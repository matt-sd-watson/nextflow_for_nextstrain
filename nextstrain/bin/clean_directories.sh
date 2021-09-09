#!/bin/bash

# clean up the fasta, tree, and json files for refine iterations as they are not needed and take up space
find $1/ -type f \( -name "*.fa" -o -name "*.fasta" -o -name "*.json" -o -name "*.nwk" \) -exec rm -rf {} \;

rm -rf $2/all_edited/ $2/all/
