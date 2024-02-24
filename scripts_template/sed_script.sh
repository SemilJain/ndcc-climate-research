#!/bin/bash

# Check if all required arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <line_number> <replacement_text> <file_name>"
    exit 1
fi

# Assign input arguments to variables
line_number="$1"
replacement_text="$2"
file_path="$3"

# Check if file exists
if [ ! -f "$file_path" ]; then
    echo "Error: File '$file_path' not found."
    exit 1
fi

# Use sed to replace the line
sed -i "${line_number}s|.*|${replacement_text}|" "${file_path}"
