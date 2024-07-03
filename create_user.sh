#!/bin/bash



# Ensure that script runs with one argument
if [ "$#" -ne 1 ]; then
    echo "Usage: bash $0 <name-of-text-file>"
    exit 1
fi

