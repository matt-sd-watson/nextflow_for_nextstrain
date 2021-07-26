#!/bin/bash


rm -r $1

find $2/ -type f \( -name "*.fa" -o -name "*.fasta" -o -name "*.json" \) -exec rm -rf {} \;


