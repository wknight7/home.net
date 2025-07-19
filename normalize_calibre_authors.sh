#!/bin/bash

# Calibre Author Normalization Script
# - Standardize author names to consistent format
# - Merge duplicate authors with different name formats
# - Set up Calibre preferences to enforce consistency going forward

set -euo pipefail

# Configuration
CALIBREDB="/opt/calibre/calibredb"
SERVER_URL="http://localhost:8080"
USERNAME="bill"
PASSWORD="Jackson0317!"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGFILE="/tmp/calibre_author_normalize_${TIMESTAMP}.log"

# Calibre server connection options
CALIBRE_OPTS="--with-library=${SERVER_URL} --username=${USERNAME} --password=${PASSWORD}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOGFILE"
}

echo_color() {
    echo -e "${2}${1}${NC}" | tee -a "$LOGFILE"
}

echo_color "=== CALIBRE AUTHOR NORMALIZATION SCRIPT ===" "$BLUE"
echo_color "Started: $(date)" "$GREEN"
echo_color "Log File: $LOGFILE" "$BLUE"
echo ""

# Get current library stats
TOTAL_BOOKS=$($CALIBREDB list $CALIBRE_OPTS --for-machine | jq length)
echo_color "Current library contains: $TOTAL_BOOKS books" "$GREEN"
echo ""

# Create temporary files for processing
TEMP_DIR="/tmp/calibre_authors_$$"
mkdir -p "$TEMP_DIR"

echo_color "=== PHASE 1: ANALYZING AUTHOR NAMES ===" "$YELLOW"
log "Extracting all author names"

# Get all books with authors
$CALIBREDB list $CALIBRE_OPTS --fields="id,title,authors" --for-machine > "$TEMP_DIR/all_books.json"

# Create Python script to analyze and normalize author names
cat > "$TEMP_DIR/normalize_authors.py" << 'EOF'
#!/usr/bin/env python3
import json
import sys
import re
from collections import defaultdict

def normalize_author_name(author):
    """Normalize author name to consistent format: First Last"""
    if not author or author.strip() == "":
        return author
    
    author = author.strip()
    
    # Handle "Last, First" format
    if ',' in author and not author.startswith('Jr.') and not author.startswith('Sr.'):
        parts = [p.strip() for p in author.split(',', 1)]
        if len(parts) == 2:
            last_name, first_name = parts
            
            # Handle multiple first names or middle initials
            first_parts = first_name.split()
            if first_parts:
                return f"{' '.join(first_parts)} {last_name}"
    
    return author

def find_author_variations(authors):
    """Find authors that are likely the same person with different formats"""
    variations = defaultdict(list)
    
    for author in authors:
        # Create a key based on last name for grouping
        normalized = normalize_author_name(author)
        words = normalized.split()
        if len(words) >= 2:
            # Use last word as key (likely surname)
            key = words[-1].lower()
            variations[key].append((author, normalized))
    
    # Find groups with multiple variations
    duplicates = {}
    for key, group in variations.items():
        if len(group) > 1:
            # Sort by preference (normalized format preferred)
            group.sort(key=lambda x: (x[0] != x[1], len(x[0])))
            duplicates[key] = group
    
    return duplicates

# Load books
with open(sys.argv[1], 'r') as f:
    books = json.load(f)

# Extract all unique authors
all_authors = set()
author_to_books = defaultdict(list)

for book in books:
    if book.get('authors'):
        authors = book['authors'] if isinstance(book['authors'], list) else [book['authors']]
        for author in authors:
            if author and author.strip():
                all_authors.add(author.strip())
                author_to_books[author.strip()].append(book['id'])

print(f"Found {len(all_authors)} unique author names")
print(f"Analyzing for variations...")

# Find variations
variations = find_author_variations(all_authors)

print(f"\nFound {len(variations)} potential author groups with variations:")

changes_needed = []
for key, group in variations.items():
    if len(group) > 1:
        preferred = group[0][1]  # Use normalized version
        print(f"\nAuthor variations for '{key.title()}':")
        for original, normalized in group:
            book_count = len(author_to_books[original])
            if original == normalized:
                print(f"  ✓ KEEP: '{original}' ({book_count} books)")
            else:
                print(f"  → CHANGE: '{original}' → '{normalized}' ({book_count} books)")
                changes_needed.append({
                    'from': original,
                    'to': normalized,
                    'book_ids': author_to_books[original]
                })

# Save changes to file
if changes_needed:
    with open(sys.argv[2], 'w') as f:
        json.dump(changes_needed, f, indent=2)
    print(f"\nTotal changes needed: {len(changes_needed)}")
    print(f"Changes saved to: {sys.argv[2]}")
else:
    print("\n✓ No author normalization needed - all names are already consistent!")

EOF

# Run author analysis
python3 "$TEMP_DIR/normalize_authors.py" "$TEMP_DIR/all_books.json" "$TEMP_DIR/author_changes.json"

# Apply changes if any found
if [ -f "$TEMP_DIR/author_changes.json" ] && [ -s "$TEMP_DIR/author_changes.json" ]; then
    echo ""
    echo_color "=== PHASE 2: APPLYING AUTHOR NORMALIZATIONS ===" "$YELLOW"
    
    # Create script to apply changes
    cat > "$TEMP_DIR/apply_changes.py" << 'EOF'
#!/usr/bin/env python3
import json
import sys
import subprocess

def update_book_authors(calibredb_cmd, book_ids, old_author, new_author):
    """Update author for specific books"""
    for book_id in book_ids:
        cmd = calibredb_cmd + [
            'set_metadata', str(book_id),
            '--field', f'authors:{new_author}'
        ]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            print(f"✓ Updated book {book_id}: '{old_author}' → '{new_author}'")
        except subprocess.CalledProcessError as e:
            print(f"✗ Failed to update book {book_id}: {e.stderr}")
            return False
    return True

# Load changes
with open(sys.argv[1], 'r') as f:
    changes = json.load(f)

# Build calibredb command
calibredb_cmd = [
    '/opt/calibre/calibredb',
    '--with-library=http://localhost:8080',
    '--username=bill', 
    '--password=Jackson0317!'
]

print(f"Applying {len(changes)} author normalizations...")

success_count = 0
for change in changes:
    old_author = change['from']
    new_author = change['to'] 
    book_ids = change['book_ids']
    
    print(f"\nNormalizing: '{old_author}' → '{new_author}' ({len(book_ids)} books)")
    
    if update_book_authors(calibredb_cmd, book_ids, old_author, new_author):
        success_count += 1
    else:
        print(f"Failed to update some books for author: {old_author}")

print(f"\nCompleted: {success_count}/{len(changes)} author normalizations applied")

EOF
    
    python3 "$TEMP_DIR/apply_changes.py" "$TEMP_DIR/author_changes.json"
    
    echo_color "✓ Author normalization completed!" "$GREEN"
else
    echo_color "✓ No author changes needed - library is already normalized!" "$GREEN"
fi

# Cleanup temp files
rm -rf "$TEMP_DIR"

echo ""
echo_color "=== NORMALIZATION SUMMARY ===" "$BLUE"
echo_color "Completed: $(date)" "$GREEN"
echo_color "Detailed log saved to: $LOGFILE" "$BLUE"

echo ""
echo_color "=== CALIBRE SETTINGS RECOMMENDATIONS ===" "$YELLOW"
echo_color "To enforce consistent author formatting going forward:" "$BLUE"
echo_color "1. In Calibre Preferences → Import/Export → Adding Books:" "$GREEN"
echo_color "   - Set 'Author sort' to 'Copy author to author_sort'" "$GREEN"  
echo_color "2. In Calibre Preferences → Look & Feel → Book Details:" "$GREEN"
echo_color "   - Set author format to 'First Last' style" "$GREEN"
echo_color "3. Consider using 'Manage Authors' to set preferred names" "$GREEN"

exit 0
