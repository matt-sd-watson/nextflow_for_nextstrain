#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

include { create_subset; create_fasta; rename_headers } from "./preprocessing/preprocessing.nf"

include { nextstrain_filter; nextstrain_align; nextstrain_tree; nextstrain_tree_refine_clock_iterations; nextstrain_traits; nextstrain_ancestral; nextstrain_translate; nextstrain_clades; nextstrain_export } from "./pipeline/pipeline.nf"


workflow {
	
	// need to fix the python renaming script to be able to handle strings
	iterations = Channel.of( 1..10 )
	clocks = Channel.of( 1..10 )
	metadata_file = params.metadata
	main: 
           create_subset(metadata_file, iterations)
           create_fasta(create_subset.out)
	   rename_headers(create_fasta.out)
	   nextstrain_filter(rename_headers.out)
	   nextstrain_align(nextstrain_filter.out)
	   nextstrain_tree(nextstrain_align.out)
	   nextstrain_tree_refine_clock_iterations(nextstrain_tree.out, clocks)

}




