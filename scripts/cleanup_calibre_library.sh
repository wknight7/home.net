#!/bin/bash

# Calibre Library Cleanup Script
# - Remove duplicate books (keeping .epub format when available)
# - Remove non-English books
# - Use Calibre's built-in database tools for safety

set -euo pipefail

# Configuration
LIBRARY_PATH="/media/books/library"
CALIBREDB="/opt/calibre/calibredb"
SERVER_URL="http://localhost:8080"
USERNAME="bill"
PASSWORD="Jackson0317!"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGFILE="/tmp/calibre_cleanup_${TIMESTAMP}.log"

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

echo_color "=== CALIBRE LIBRARY CLEANUP SCRIPT ===" "$BLUE"
echo_color "Started: $(date)" "$GREEN"
echo_color "Library: $LIBRARY_PATH" "$BLUE"
echo_color "Log File: $LOGFILE" "$BLUE"
echo ""

# Get current library stats
TOTAL_BOOKS=$($CALIBREDB list $CALIBRE_OPTS --for-machine | jq length)
echo_color "Current library contains: $TOTAL_BOOKS books" "$GREEN"
echo ""

# Phase 1: Find and remove non-English books
echo_color "=== PHASE 1: REMOVING NON-ENGLISH BOOKS ===" "$YELLOW"
log "Starting non-English book removal"

# Get all books with languages field - remove books with non-English languages or empty language arrays
NON_ENGLISH_BOOKS=$($CALIBREDB list $CALIBRE_OPTS \
    --fields="id,title,authors,languages" --for-machine | \
    jq -r '.[] | select(
        .languages == null or 
        .languages == [] or 
        (.languages | tostring | test("eng|en|en-|english|English|unknown"; "i") | not)
    ) | .id' || true)

if [ -n "$NON_ENGLISH_BOOKS" ]; then
    NON_ENGLISH_COUNT=$(echo "$NON_ENGLISH_BOOKS" | wc -l)
    echo_color "Found $NON_ENGLISH_COUNT non-English books to remove" "$YELLOW"
    
    # Convert to comma-separated list for calibredb
    NON_ENGLISH_IDS=$(echo "$NON_ENGLISH_BOOKS" | tr '\n' ',' | sed 's/,$//')
    
    if [ -n "$NON_ENGLISH_IDS" ]; then
        echo_color "Removing non-English books (IDs: $NON_ENGLISH_IDS)" "$RED"
        $CALIBREDB remove $CALIBRE_OPTS "$NON_ENGLISH_IDS"
        log "Removed $NON_ENGLISH_COUNT non-English books"
        echo_color "✓ Successfully removed $NON_ENGLISH_COUNT non-English books" "$GREEN"
    fi
else
    echo_color "✓ No non-English books found" "$GREEN"
fi

echo ""

# Phase 2: Find and handle duplicates
echo_color "=== PHASE 2: HANDLING DUPLICATE BOOKS ===" "$YELLOW"
log "Starting duplicate detection"

# Create temporary files for processing
TEMP_DIR="/tmp/calibre_cleanup_$$"
mkdir -p "$TEMP_DIR"

# Get all books with title, authors, and formats
$CALIBREDB list $CALIBRE_OPTS \
    --fields="id,title,authors,formats" --for-machine > "$TEMP_DIR/all_books.json"

# Process duplicates using Python for complex logic
cat > "$TEMP_DIR/find_duplicates.py" << 'EOF'
#!/usr/bin/env python3
import json
import sys
from collections import defaultdict
import re

def normalize_title(title):
    """Normalize title for comparison"""
    # Remove common subtitle separators and normalize
    title = re.sub(r'[:\-–—]\s*.*$', '', title)  # Remove after : or -
    title = re.sub(r'\s*\([^)]*\)\s*', ' ', title)  # Remove parentheses content
    title = re.sub(r'\s+', ' ', title.strip().lower())  # Normalize whitespace
    return title

def normalize_author(author):
    """Normalize author name for comparison"""
    # Handle "Last, First" vs "First Last"
    if ',' in author:
        parts = [p.strip() for p in author.split(',')]
        if len(parts) == 2:
            author = f"{parts[1]} {parts[0]}"
    return author.strip().lower()

def get_format_priority(formats):
    """Return priority score for formats (higher is better)"""
    if not formats:
        return 0
    
    # Handle both list and string formats
    if isinstance(formats, list):
        format_list = ','.join(formats).lower()
    else:
        format_list = str(formats).lower()
    
    if 'epub' in format_list:
        return 100
    elif 'mobi' in format_list:
        return 90
    elif 'azw3' in format_list:
        return 85
    elif 'pdf' in format_list:
        return 70
    else:
        return 50

# Load books
with open(sys.argv[1], 'r') as f:
    books = json.load(f)

# Group by normalized title + first author
book_groups = defaultdict(list)
for book in books:
    title = normalize_title(book['title'])
    authors = book['authors'] if book['authors'] else ['Unknown']
    first_author = normalize_author(authors[0] if isinstance(authors, list) else str(authors))
    
    key = f"{title}|||{first_author}"
    book_groups[key].append(book)

# Find duplicates and decide which to keep
duplicates_to_remove = []
duplicate_groups = 0

for key, group in book_groups.items():
    if len(group) > 1:
        duplicate_groups += 1
        # Sort by format preference (keep best format)
        group.sort(key=lambda x: get_format_priority(x.get('formats', '')), reverse=True)
        
        # Keep the first one (best format), mark others for removal
        to_keep = group[0]
        to_remove = group[1:]
        
        print(f"DUPLICATE GROUP: {group[0]['title']} by {group[0]['authors']}")
        print(f"  KEEPING: ID {to_keep['id']} (formats: {to_keep.get('formats', 'none')})")
        
        for book in to_remove:
            print(f"  REMOVING: ID {book['id']} (formats: {book.get('formats', 'none')})")
            duplicates_to_remove.append(str(book['id']))

print(f"\nSUMMARY:")
print(f"Total books: {len(books)}")
print(f"Duplicate groups found: {duplicate_groups}")
print(f"Books to remove: {len(duplicates_to_remove)}")

# Output IDs to remove
if duplicates_to_remove:
    with open(sys.argv[2], 'w') as f:
        f.write(','.join(duplicates_to_remove))
EOF

# Run duplicate detection
python3 "$TEMP_DIR/find_duplicates.py" "$TEMP_DIR/all_books.json" "$TEMP_DIR/duplicates_to_remove.txt"

# Remove duplicates if any found
if [ -f "$TEMP_DIR/duplicates_to_remove.txt" ] && [ -s "$TEMP_DIR/duplicates_to_remove.txt" ]; then
    DUPLICATE_IDS=$(cat "$TEMP_DIR/duplicates_to_remove.txt")
    DUPLICATE_COUNT=$(echo "$DUPLICATE_IDS" | tr ',' '\n' | wc -l)
    
    echo_color "Removing $DUPLICATE_COUNT duplicate books (IDs: $DUPLICATE_IDS)" "$RED"
    $CALIBREDB remove $CALIBRE_OPTS "$DUPLICATE_IDS"
    log "Removed $DUPLICATE_COUNT duplicate books"
    echo_color "✓ Successfully removed $DUPLICATE_COUNT duplicate books" "$GREEN"
else
    echo_color "✓ No duplicate books found" "$GREEN"
fi

# Cleanup temp files
rm -rf "$TEMP_DIR"

echo ""

# Final stats
FINAL_BOOKS=$($CALIBREDB list $CALIBRE_OPTS --for-machine | jq length)
REMOVED_TOTAL=$((TOTAL_BOOKS - FINAL_BOOKS))

echo_color "=== CLEANUP SUMMARY ===" "$BLUE"
echo_color "Started with: $TOTAL_BOOKS books" "$GREEN"
echo_color "Removed: $REMOVED_TOTAL books" "$RED"
echo_color "Final count: $FINAL_BOOKS books" "$GREEN"
echo_color "Completed: $(date)" "$GREEN"
echo_color "Detailed log saved to: $LOGFILE" "$BLUE"

exit 0
