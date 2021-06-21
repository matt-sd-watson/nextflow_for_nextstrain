#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

include { nextstrain_augur_refine_clock_iterations; nextstrain_random_subsets } from "./workflow.nf"


workflow {
	
	if (params.mode == "refine_iterations") {
		nextstrain_augur_refine_clock_iterations()

	}
	if (params.mode == "random_subsets") {
		nextstrain_random_subsets()

}

}



