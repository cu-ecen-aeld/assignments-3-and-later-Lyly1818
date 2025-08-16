#!/bin/bash

# writer.sh - Script to write a text string to a file
# Usage: writer.sh <writefile> <writestr>
# Arguments:
#   writefile - Full path to the file (including filename)
#   writestr  - Text string to write to the file

# Check if exactly 2 arguments are provided
if [ $# -ne 2 ]; then
    echo "Error: Two arguments required"
    echo "Usage: $0 <writefile> <writestr>"
    exit 1
fi

# Store arguments in variables
writefile="$1"
writestr="$2"

# Check if the first argument (writefile) is empty
if [ -z "$writefile" ]; then
    echo "Error: File path cannot be empty"
    exit 1
fi

# Check if the second argument (writestr) is empty
if [ -z "$writestr" ]; then
    echo "Error: Write string cannot be empty"
    exit 1
fi

# Extract the directory path from the file path
dirpath=$(dirname "$writefile")

# Create the directory path if it doesn't exist
if ! mkdir -p "$dirpath" 2>/dev/null; then
    echo "Error: Failed to create directory path: $dirpath"
    exit 1
fi

# Write the string to the file (overwriting if it exists)
if ! echo "$writestr" > "$writefile" 2>/dev/null; then
    echo "Error: Failed to create or write to file: $writefile"
    exit 1
fi

# Success - exit with status 0 (implicit)
exit 0

