#!/bin/bash

# Comprehensive book cleanup script - Option A
# 1. Process downloads directory (add new English books, skip duplicates)
# 2. Remove temp directory (all duplicates confirmed)
# 3. Clean up downloads directory after processing

DOWNLOADS_DIR="/media/books/downloads"
TEMP_DIR="/media/books/temp"
CALIBRE_CMD="/opt/calibre/calibredb"
EBOOK_META="/opt/calibre/ebook-meta"
SERVER_URL="http://localhost:8080"
LOG_FILE="/tmp/book_cleanup.log"

echo "=== BOOK CLEANUP PROCESS STARTED ===" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "Processing downloads: $DOWNLOADS_DIR" >> "$LOG_FILE"
echo "Removing temp: $TEMP_DIR" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Counters
downloads_total=0
downloads_new=0
downloads_duplicates=0
downloads_non_english=0
downloads_errors=0

echo "PHASE 1: Processing downloads directory..." >> "$LOG_FILE"
echo "Finding all book files in downloads..." >> "$LOG_FILE"

find "$DOWNLOADS_DIR" -type f \( -name "*.epub" -o -name "*.mobi" -o -name "*.azw*" -o -name "*.pdf" \) | while read -r book_file; do
    downloads_total=$((downloads_total + 1))
    filename=$(basename "$book_file")
    echo "Processing $downloads_total: $filename" >> "$LOG_FILE"
    
    # Check language
    language=$(sudo -u bill "$EBOOK_META" "$book_file" 2>/dev/null | grep -i "Languages" | awk -F: '{print $2}' | tr -d ' ')
    
    if [ -z "$language" ]; then
        language="unknown"
        echo "  No language detected, assuming English" >> "$LOG_FILE"
    else
        echo "  Language: $language" >> "$LOG_FILE"
    fi
    
    # Check if English
    case "$language" in
        "eng"|"en"|"en-"*|"english"|"unknown")
            echo "  English book - attempting to add..." >> "$LOG_FILE"
            
            # Try to add to Calibre
            result=$(sudo -u bill "$CALIBRE_CMD" add --with-library="$SERVER_URL" "$book_file" 2>&1)
            
            if echo "$result" | grep -q "Added book ids:"; then
                downloads_new=$((downloads_new + 1))
                book_id=$(echo "$result" | grep "Added book ids:" | awk '{print $4}')
                echo "  ✓ SUCCESS: Added with ID $book_id" >> "$LOG_FILE"
                echo "    New book added: $filename"
            elif echo "$result" | grep -q "already exist"; then
                downloads_duplicates=$((downloads_duplicates + 1))
                echo "  ⚠ DUPLICATE: Book already exists" >> "$LOG_FILE"
            else
                downloads_errors=$((downloads_errors + 1))
                echo "  ✗ ERROR: $result" >> "$LOG_FILE"
            fi
            ;;
        *)
            downloads_non_english=$((downloads_non_english + 1))
            echo "  ✗ SKIPPED: Non-English book ($language)" >> "$LOG_FILE"
            ;;
    esac
    
    echo "" >> "$LOG_FILE"
done

echo "" >> "$LOG_FILE"
echo "PHASE 1 COMPLETE - Downloads Processing Summary:" >> "$LOG_FILE"
echo "  Total files processed: $downloads_total" >> "$LOG_FILE"
echo "  New books added: $downloads_new" >> "$LOG_FILE"
echo "  Duplicates skipped: $downloads_duplicates" >> "$LOG_FILE"
echo "  Non-English skipped: $downloads_non_english" >> "$LOG_FILE"
echo "  Errors: $downloads_errors" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "PHASE 2: Removing temp directory (confirmed all duplicates)..." >> "$LOG_FILE"
if [ -d "$TEMP_DIR" ]; then
    temp_file_count=$(find "$TEMP_DIR" -type f | wc -l)
    temp_dir_count=$(find "$TEMP_DIR" -type d | wc -l)
    echo "  Temp directory contains: $temp_file_count files in $temp_dir_count directories" >> "$LOG_FILE"
    
    # Create backup list before deletion
    echo "  Creating backup list of temp contents..." >> "$LOG_FILE"
    find "$TEMP_DIR" -type f > "/tmp/deleted_temp_books_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "  Removing temp directory: $TEMP_DIR" >> "$LOG_FILE"
    rm -rf "$TEMP_DIR"
    
    if [ ! -d "$TEMP_DIR" ]; then
        echo "  ✓ SUCCESS: Temp directory removed" >> "$LOG_FILE"
        echo "Temp directory removed successfully ($temp_file_count files deleted)"
    else
        echo "  ✗ ERROR: Failed to remove temp directory" >> "$LOG_FILE"
    fi
else
    echo "  Temp directory not found - nothing to remove" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"
echo "=== CLEANUP PROCESS COMPLETED ===" >> "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Print final summary to console
echo "=== BOOK CLEANUP SUMMARY ==="
echo "Downloads processed: $downloads_total files"
echo "New books added: $downloads_new"
echo "Duplicates skipped: $downloads_duplicates" 
echo "Non-English skipped: $downloads_non_english"
echo "Errors: $downloads_errors"
echo ""
echo "Temp directory: REMOVED"
echo ""
echo "Full log available at: $LOG_FILE"
echo "=== PROCESS COMPLETE ==="
