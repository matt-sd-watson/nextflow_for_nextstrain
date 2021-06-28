#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

include { nextstrain_augur_refine_clock_iterations; nextstrain_random_subsets; nextstrain_by_lineage  } from "./workflow.nf"

include { nextstrain_tree; nextstrain_tree_refine; nextstrain_tree_refine_clock_iterations } from "./pipeline/pipeline.nf"


// Check input path parameters to see if the files exist if they have been specified
// https://github.com/nf-core/cutandrun/blob/86cb2cc89da77957dc575786d9d7277148109a91/workflows/cutandrun.nf#L13

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
	    clocks = Channel.of(1..params.clock)
	
	if (params.mode == "refine_iterations") {
		
		   nextstrain_augur_refine_clock_iterations()
		   nextstrain_tree(nextstrain_augur_refine_clock_iterations.out)
		   nextstrain_tree_refine_clock_iterations(nextstrain_tree.out, clocks)		

	}
	if (params.mode == "random_subsets") {
		nextstrain_random_subsets()
	}

	if (params.mode == "lineages") {
		nextstrain_by_lineage()

	}

}




