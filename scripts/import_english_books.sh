#!/bin/bash

# Script to import only English books from temp directory to Calibre library
# and then remove the temp directory

TEMP_DIR="/media/books/temp"
CALIBRE_CMD="/opt/calibre/calibredb"
EBOOK_META="/opt/calibre/ebook-meta"
SERVER_URL="http://localhost:8080"
LOG_FILE="/tmp/book_import.log"

echo "Starting book import process at $(date)" > "$LOG_FILE"
echo "Processing books from: $TEMP_DIR" >> "$LOG_FILE"

# Counters
total_files=0
english_books=0
non_english_books=0
added_books=0
duplicate_books=0
error_books=0

# Find all book files
echo "Finding book files..." >> "$LOG_FILE"
find "$TEMP_DIR" -type f \( -name "*.epub" -o -name "*.mobi" -o -name "*.azw*" -o -name "*.pdf" \) | while read -r book_file; do
    total_files=$((total_files + 1))
    echo "Processing file $total_files: $(basename "$book_file")" >> "$LOG_FILE"
    
    # Check language using ebook-meta
    language=$(sudo -u bill "$EBOOK_META" "$book_file" 2>/dev/null | grep -i "Languages" | awk '{print $3}' | tr -d '[:space:]')
    
    if [ -z "$language" ]; then
        echo "  Warning: No language metadata found, assuming English" >> "$LOG_FILE"
        language="eng"
    fi
    
    echo "  Language detected: $language" >> "$LOG_FILE"
    
    # Check if it's English (eng, en, en-US, etc.)
    if [[ "$language" =~ ^(eng|en|en-.*|english)$ ]]; then
        english_books=$((english_books + 1))
        echo "  Adding English book to library..." >> "$LOG_FILE"
        
        # Add to Calibre library
        result=$(sudo -u bill "$CALIBRE_CMD" add --with-library="$SERVER_URL" "$book_file" 2>&1)
        
        if echo "$result" | grep -q "Added book ids:"; then
            added_books=$((added_books + 1))
            book_id=$(echo "$result" | grep "Added book ids:" | awk '{print $4}')
            echo "  Successfully added with ID: $book_id" >> "$LOG_FILE"
        elif echo "$result" | grep -q "already exists"; then
            duplicate_books=$((duplicate_books + 1))
            echo "  Book already exists in library (duplicate)" >> "$LOG_FILE"
        else
            error_books=$((error_books + 1))
            echo "  Error adding book: $result" >> "$LOG_FILE"
        fi
    else
        non_english_books=$((non_english_books + 1))
        echo "  Skipping non-English book (language: $language)" >> "$LOG_FILE"
    fi
    
    echo "  ---" >> "$LOG_FILE"
done

# Print summary
echo "Import process completed at $(date)" >> "$LOG_FILE"
echo "SUMMARY:" >> "$LOG_FILE"
echo "  Total files processed: $total_files" >> "$LOG_FILE"
echo "  English books: $english_books" >> "$LOG_FILE"
echo "  Non-English books: $non_english_books" >> "$LOG_FILE"
echo "  Successfully added: $added_books" >> "$LOG_FILE"
echo "  Duplicates skipped: $duplicate_books" >> "$LOG_FILE"
echo "  Errors: $error_books" >> "$LOG_FILE"

echo "Import completed. Check $LOG_FILE for details."
