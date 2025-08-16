#!/bin/bash

# Check if exactly 2 arguments are provided
if [ $# -ne 2 ]; then
    echo "Error: Two arguments are required"
    echo "Usage: $0 <filesdir> <searchstr>"
    exit 1
fi

# Assign arguments to variables
filesdir="$1"
searchstr="$2"

# Check if filesdir exists and is a directory
if [ ! -d "$filesdir" ]; then
    echo "Error: $filesdir is not a directory"
    exit 1
fi

# Count files in the directory (recursively)
file_count=$(find "$filesdir" -type f | wc -l)

# Count matching lines containing the search string
matching_lines=$(grep -r "$searchstr" "$filesdir" 2>/dev/null | wc -l)

# Print the result
echo "The number of files are $file_count and the number of matching lines are $matching_lines"

exit 0 
