#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

include { create_subset; create_subset_by_lineage; create_fasta; rename_headers } from "./preprocessing/preprocessing.nf"

include { nextstrain_filter; nextstrain_align; nextstrain_tree; nextstrain_tree_refine; nextstrain_tree_refine_clock_iterations; nextstrain_traits; nextstrain_ancestral; nextstrain_translate; nextstrain_clades; nextstrain_export } from "./pipeline/pipeline.nf"

include { manipulate_json; clean_directories } from "./postprocessing/postprocessing.nf"


workflow nextstrain_augur_refine_clock_iterations {

	main: 
	   clocks = Channel.of(1..params.clock)
	   iterations = Channel.of(params.start_iteration..params.stop_iteration)
	   metadata_file = params.metadata
           create_subset(iterations)
           create_fasta(create_subset.out.metadata)
	   meta_with_fasta = create_subset.out.metadata.join(create_fasta.out.fasta)
	   rename_headers(meta_with_fasta)
	   meta_with_fasta_filtered = create_subset.out.metadata.join(rename_headers.out.renamed)
	   nextstrain_filter(meta_with_fasta_filtered)
	   nextstrain_align(nextstrain_filter.out.filtered)
	   nextstrain_tree(nextstrain_align.out.alignment)
           refine_inputs = nextstrain_tree.out.tree.join(create_subset.out.metadata).join(nextstrain_align.out.alignment)
	   nextstrain_tree_refine_clock_iterations(refine_inputs, clocks)
	emit: 
	   tree = nextstrain_tree_refine_clock_iterations.out.refined_tree
	   dirs = nextstrain_tree_refine_clock_iterations.out.final_directories
}

workflow nextstrain_random_subsets {

	main:
	   iterations = Channel.of(params.start_iteration..params.stop_iteration)
	   metadata_file = params.metadata 
           create_subset(iterations)
           create_fasta(create_subset.out.metadata)
	   meta_with_fasta = create_subset.out.metadata.join(create_fasta.out.fasta)
	   rename_headers(meta_with_fasta)
	   meta_with_fasta_filtered = create_subset.out.metadata.join(rename_headers.out.renamed)
	   nextstrain_filter(meta_with_fasta_filtered)
	   nextstrain_align(nextstrain_filter.out.filtered)
	   nextstrain_tree(nextstrain_align.out.alignment)
           refine_inputs = nextstrain_tree.out.tree.join(create_subset.out.metadata).join(nextstrain_align.out.alignment)
           nextstrain_tree_refine(refine_inputs)
	   traits_input = create_subset.out.metadata.join(nextstrain_tree_refine.out.refined)
	   nextstrain_traits(traits_input)
           ancestral_inputs = nextstrain_align.out.alignment.join(nextstrain_tree_refine.out.refined)
	   nextstrain_ancestral(ancestral_inputs)
           translate_inputs = nextstrain_tree_refine.out.refined.join(nextstrain_ancestral.out.ancestral)
           nextstrain_translate(translate_inputs)
	   clades_input = translate_inputs.join(nextstrain_translate.out.translation)
	   nextstrain_clades(clades_input)
           final_input = refine_inputs.join(clades_input).join(
           nextstrain_traits.out.traits).join(nextstrain_clades.out.clades).distinct()

           nextstrain_export(final_input)
           manipulate_json(nextstrain_export.out.export_json)

	emit: 
	   jsons = manipulate_json.out.edited_json
	   dirs = manipulate_json.out.final_dirs
	   

}

workflow nextstrain_by_lineage {

	main: 
	   lineage_list = Channel.fromList(params.lineages) 
           create_subset_by_lineage(lineage_list)
           create_fasta(create_subset_by_lineage.out.lineage)
	   meta_with_fasta = create_subset_by_lineage.out.lineage.join(create_fasta.out.fasta)
	   rename_headers(meta_with_fasta)
	   meta_with_fasta_filtered = create_subset_by_lineage.out.lineage.join(rename_headers.out.renamed)
	   nextstrain_filter(meta_with_fasta_filtered)
	   nextstrain_align(nextstrain_filter.out.filtered)
	   nextstrain_tree(nextstrain_align.out.alignment)
           refine_inputs = nextstrain_tree.out.tree.join(create_subset_by_lineage.out.lineage).join(nextstrain_align.out.alignment)
           nextstrain_tree_refine(refine_inputs)
	   traits_input = create_subset_by_lineage.out.lineage.join(nextstrain_tree_refine.out.refined)
	   nextstrain_traits(traits_input)
           ancestral_inputs = nextstrain_align.out.alignment.join(nextstrain_tree_refine.out.refined)
	   nextstrain_ancestral(ancestral_inputs)
           translate_inputs = nextstrain_tree_refine.out.refined.join(nextstrain_ancestral.out.ancestral)
           nextstrain_translate(translate_inputs)
	   clades_input = translate_inputs.join(nextstrain_translate.out.translation)
	   nextstrain_clades(clades_input)
           final_input = refine_inputs.join(clades_input).join(
           nextstrain_traits.out.traits).join(nextstrain_clades.out.clades).distinct()

           nextstrain_export(final_input)
           manipulate_json(nextstrain_export.out.export_json)

	emit: 
	   jsons = manipulate_json.out.edited_json
	   dirs = manipulate_json.out.final_dirs

}


workflow directory_cleanup {
	
	take: location_dir

	main: 
	clean_directories(location_dir)

}




