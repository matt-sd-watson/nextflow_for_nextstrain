#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

include { annotate_trees_by_lineage } from "./workflow.nf"

workflow {
	
	main:
	   annotate_trees_by_lineage()

	}





