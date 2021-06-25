#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

include { nextstrain_augur_refine_clock_iterations; nextstrain_random_subsets; nextstrain_by_lineage  } from "./workflow.nf"

include { nextstrain_tree; nextstrain_tree_refine; nextstrain_tree_refine_clock_iterations } from "./pipeline/pipeline.nf"


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




