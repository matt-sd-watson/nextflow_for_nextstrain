#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

include { create_subset; create_fasta; rename_headers } from "./preprocessing/preprocessing.nf"

include { nextstrain_filter; nextstrain_align; nextstrain_tree; nextstrain_tree_refine; nextstrain_tree_refine_clock_iterations; nextstrain_traits; nextstrain_ancestral; nextstrain_translate; nextstrain_clades; nextstrain_export } from "./pipeline/pipeline.nf"

include { manipulate_json } from "./postprocessing/postprocessing.nf"


workflow nextstrain_augur_refine_clock_iterations{

	main: 
	   metadata_file = params.metadata
	   iterations = Channel.of(1..params.iteration)
	   clocks = Channel.of(1..params.clock)
           create_subset(metadata_file, iterations)
           create_fasta(create_subset.out)
	   rename_headers(create_fasta.out)
	   nextstrain_filter(rename_headers.out)
	   nextstrain_align(nextstrain_filter.out)
	   nextstrain_tree(nextstrain_align.out)
	   nextstrain_tree_refine_clock_iterations(nextstrain_tree.out, clocks)

}

workflow nextstrain_random_subsets {

	main:
	   iterations = Channel.of(1..params.iteration)
	   metadata_file = params.metadata 
           create_subset(metadata_file, iterations)
           create_fasta(create_subset.out)
	   rename_headers(create_fasta.out)
	   nextstrain_filter(rename_headers.out)
	   nextstrain_align(nextstrain_filter.out)
	   nextstrain_tree(nextstrain_align.out)
	   nextstrain_tree_refine(nextstrain_tree.out)
	   nextstrain_traits(nextstrain_tree_refine.out)
	   nextstrain_ancestral(nextstrain_tree_refine.out)
	   nextstrain_translate(nextstrain_ancestral.out)
	   nextstrain_clades(nextstrain_translate.out)
	   nextstrain_export(nextstrain_clades.out)
	   manipulate_json(nextstrain_export.out)
	   

}






