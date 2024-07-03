#!/bin/bash



# Ensure that script runs with one argument
if [ "$#" -ne 1 ]; then
    echo "Usage: bash $0 <name-of-text-file>"
    exit 1
fi

# get file name from the arg
FILE =  $1


# check if the file exist
if [ ! -f "$FILE" ]; then
    echo "File $FILE not found!"
    exit 1
fi
