#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

include { create_subset; create_subset_by_lineage; create_fasta; rename_headers } from "./preprocessing/preprocessing.nf"

include { nextstrain_filter; nextstrain_align; nextstrain_tree; nextstrain_tree_refine; nextstrain_tree_refine_clock_iterations; nextstrain_traits; nextstrain_ancestral; nextstrain_translate; nextstrain_clades; nextstrain_export } from "./pipeline/pipeline.nf"

include { manipulate_json } from "./postprocessing/postprocessing.nf"


workflow nextstrain_augur_refine_clock_iterations {

	main: 
	   iterations = Channel.of(params.start_iteration..params.stop_iteration)
	   metadata_file = params.metadata
           create_subset(metadata_file, iterations)
           create_fasta(create_subset.out)
	   rename_headers(create_fasta.out)
	   nextstrain_filter(rename_headers.out)
	   nextstrain_align(nextstrain_filter.out)
	   emit: 
	      nextstrain_align.out

}

workflow nextstrain_random_subsets {

	main:
	   iterations = Channel.of(params.start_iteration..params.stop_iteration)
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

workflow nextstrain_by_lineage {

	main: 
	   lineage_list = Channel.fromList(params.lineages) 
           create_subset_by_lineage(lineage_list)
           create_fasta(create_subset_by_lineage.out)
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
