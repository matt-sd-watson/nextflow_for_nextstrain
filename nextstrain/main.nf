#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

include { nextstrain_augur_refine_clock_iterations; nextstrain_random_subsets; nextstrain_by_lineage; directory_cleanup; nextstrain_random_subsets_no_align } from "./workflow.nf"

// re-write workflows in the separaeete file so that all that is finally imported are the workflows themselves and not individual processes
// include { nextstrain_tree; nextstrain_tree_refine; nextstrain_tree_refine_clock_iterations } from "./pipeline/pipeline.nf"

include { clean_directories } from "./postprocessing/postprocessing.nf"

include { printHelp } from "./utils/help.nf"

// Check input path parameters to see if the files exist if they have been specified
// https://github.com/nf-core/cutandrun/blob/86cb2cc89da77957dc575786d9d7277148109a91/workflows/cutandrun.nf#L13

if (params.help){
    printHelp()
    exit 0
}


checkPathParamList = [
    params.alignment_ref,
    params.metadata,
    params.colortsv,
    params.config,
    params.latlong,
    params.lineage_report,
    params.master_fasta
]

for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }


workflow {
	
	main:
	    
	if (params.mode == "refine_iterations") {
		
		   nextstrain_augur_refine_clock_iterations()
		   if (params.clean_dir == true) {
		   	directory_cleanup(nextstrain_augur_refine_clock_iterations.out.dirs)
  			}

	} else if (params.mode == "random_subsets_no_align") {
		nextstrain_random_subsets_no_align()
		if (params.clean_dir == true) {
		   	directory_cleanup(nextstrain_random_subsets_no_align.out.dirs)
  			}
	} else if (params.mode == "random_subsets") {
		nextstrain_random_subsets()
		if (params.clean_dir == true) {
		   	directory_cleanup(nextstrain_random_subsets.out.dirs)
  			}
	} else if (params.mode == "lineages") {
		nextstrain_by_lineage()
		if (params.clean_dir == true) {
		   	directory_cleanup(nextstrain_by_lineage.out.dirs)
  			}
	} else {

	println("Please select a valid mode with params.mode")
	System.exit(1)
}	

}




