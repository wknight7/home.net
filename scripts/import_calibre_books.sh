#!/bin/bash

# Calibre Book Import Script
# Processes new English books from /media/books/calibre directory
# Filters by language, prevents duplicates, adds to Calibre library
# Author: Generated for books server automation
# Usage: ./import_calibre_books.sh

IMPORT_DIR="/media/books/calibre"
CALIBRE_CMD="/opt/calibre/calibredb"
EBOOK_META="/opt/calibre/ebook-meta"
SERVER_URL="http://localhost:8080"
LOG_FILE="/tmp/calibre_import_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== CALIBRE BOOK IMPORT SCRIPT ===${NC}"
echo -e "${BLUE}Started: $(date)${NC}"
echo -e "${BLUE}Import Directory: $IMPORT_DIR${NC}"
echo -e "${BLUE}Log File: $LOG_FILE${NC}"
echo ""

# Initialize log file
{
    echo "=== CALIBRE BOOK IMPORT LOG ==="
    echo "Date: $(date)"
    echo "Import Directory: $IMPORT_DIR"
    echo "Calibre Server: $SERVER_URL"
    echo ""
} > "$LOG_FILE"

# Check if import directory exists
if [ ! -d "$IMPORT_DIR" ]; then
    echo -e "${RED}ERROR: Import directory $IMPORT_DIR does not exist!${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

# Check if Calibre tools are available
if [ ! -x "$CALIBRE_CMD" ] || [ ! -x "$EBOOK_META" ]; then
    echo -e "${RED}ERROR: Calibre tools not found in /opt/calibre/${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

# Check if Calibre server is running
if ! curl -s "$SERVER_URL" > /dev/null; then
    echo -e "${RED}ERROR: Calibre server not accessible at $SERVER_URL${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Make sure calibre-server is running${NC}"
    exit 1
fi

# Get initial library count
initial_count=$(sudo -u bill "$CALIBRE_CMD" list --with-library="$SERVER_URL" 2>/dev/null | wc -l)
echo -e "${BLUE}Current library contains: $initial_count books${NC}" | tee -a "$LOG_FILE"
echo ""

# Counters
total_files=0
processed_files=0
english_books=0
non_english_books=0
added_books=0
duplicate_books=0
error_books=0

# Find all book files in the calibre import directory
echo -e "${BLUE}Scanning for book files...${NC}" | tee -a "$LOG_FILE"
book_files=$(find "$IMPORT_DIR" -type f \( -name "*.epub" -o -name "*.mobi" -o -name "*.azw*" -o -name "*.pdf" \) 2>/dev/null)

if [ -z "$book_files" ]; then
    echo -e "${YELLOW}No book files found in $IMPORT_DIR${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}Supported formats: .epub, .mobi, .azw*, .pdf${NC}"
    exit 0
fi

total_files=$(echo "$book_files" | wc -l)
echo -e "${GREEN}Found $total_files book files to process${NC}" | tee -a "$LOG_FILE"
echo ""

# Process each book file
echo "$book_files" | while read -r book_file; do
    if [ -z "$book_file" ]; then
        continue
    fi
    
    processed_files=$((processed_files + 1))
    filename=$(basename "$book_file")
    relative_path=${book_file#$IMPORT_DIR/}
    
    echo -e "${BLUE}[$processed_files/$total_files] Processing: $relative_path${NC}"
    echo "Processing file $processed_files/$total_files: $relative_path" >> "$LOG_FILE"
    
    # Extract language metadata
    language=$(sudo -u bill "$EBOOK_META" "$book_file" 2>/dev/null | grep -i "Languages" | awk -F: '{print $2}' | tr -d ' [:cntrl:]')
    
    if [ -z "$language" ]; then
        language="unknown"
        echo "  No language metadata found, assuming English" >> "$LOG_FILE"
    else
        echo "  Language detected: $language" >> "$LOG_FILE"
    fi
    
    # Check if it's English (various formats: eng, en, en-US, english, etc.)
    case "$language" in
        "eng"|"en"|"en-"*|"english"|"English"|"unknown")
            english_books=$((english_books + 1))
            echo -e "  ${GREEN}✓ English book - importing...${NC}"
            echo "  English book detected - attempting import" >> "$LOG_FILE"
            
            # Import to Calibre library
            import_result=$(sudo -u bill "$CALIBRE_CMD" add --with-library="$SERVER_URL" "$book_file" 2>&1)
            
            if echo "$import_result" | grep -q "Added book ids:"; then
                added_books=$((added_books + 1))
                book_id=$(echo "$import_result" | grep "Added book ids:" | awk '{print $4}')
                echo -e "  ${GREEN}✓ SUCCESS: Added to library with ID $book_id${NC}"
                echo "  SUCCESS: Added with Calibre ID $book_id" >> "$LOG_FILE"
                
                # Optional: Remove original file after successful import
                # Uncomment the next two lines if you want to clean up imported files
                # rm "$book_file" 2>/dev/null
                # echo "  Original file removed after import" >> "$LOG_FILE"
                
            elif echo "$import_result" | grep -q "already exist"; then
                duplicate_books=$((duplicate_books + 1))
                echo -e "  ${YELLOW}⚠ DUPLICATE: Book already exists in library${NC}"
                echo "  DUPLICATE: Book already in library" >> "$LOG_FILE"
            else
                error_books=$((error_books + 1))
                echo -e "  ${RED}✗ ERROR: Failed to import${NC}"
                echo "  ERROR: $import_result" >> "$LOG_FILE"
            fi
            ;;
        *)
            non_english_books=$((non_english_books + 1))
            echo -e "  ${YELLOW}✗ SKIPPED: Non-English book ($language)${NC}"
            echo "  SKIPPED: Non-English book (language: $language)" >> "$LOG_FILE"
            ;;
    esac
    
    echo "" >> "$LOG_FILE"
done

# Get final library count
final_count=$(sudo -u bill "$CALIBRE_CMD" list --with-library="$SERVER_URL" 2>/dev/null | wc -l)
books_added_total=$((final_count - initial_count))

# Final summary
echo ""
echo -e "${BLUE}=== IMPORT SUMMARY ===${NC}"
echo -e "${BLUE}Completed: $(date)${NC}"
echo -e "${GREEN}Files processed: $total_files${NC}"
echo -e "${GREEN}English books found: $english_books${NC}"
echo -e "${YELLOW}Non-English books skipped: $non_english_books${NC}"
echo -e "${GREEN}Successfully imported: $added_books${NC}"
echo -e "${YELLOW}Duplicates skipped: $duplicate_books${NC}"
echo -e "${RED}Errors encountered: $error_books${NC}"
echo -e "${BLUE}Library growth: $initial_count → $final_count books (+$books_added_total)${NC}"
echo -e "${BLUE}Detailed log saved to: $LOG_FILE${NC}"

# Also save summary to log
{
    echo ""
    echo "=== FINAL SUMMARY ==="
    echo "Files processed: $total_files"
    echo "English books found: $english_books" 
    echo "Non-English books skipped: $non_english_books"
    echo "Successfully imported: $added_books"
    echo "Duplicates skipped: $duplicate_books"
    echo "Errors encountered: $error_books"
    echo "Library growth: $initial_count → $final_count books (+$books_added_total)"
    echo "Process completed: $(date)"
} >> "$LOG_FILE"

# Exit with appropriate code
if [ $error_books -gt 0 ]; then
    exit 1
else
    exit 0
fi
