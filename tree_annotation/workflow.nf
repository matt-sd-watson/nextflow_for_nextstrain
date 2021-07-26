#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

include { create_subset_by_lineage; create_fasta; nextstrain_align; nextstrain_tree  } from "./processes/process.nf"



workflow annotate_trees_by_lineage {

	main: 
	   lineage_list = Channel.fromList(params.lineages)
           create_subset_by_lineage(lineage_list)
           create_fasta(create_subset_by_lineage.out)
	   nextstrain_align(create_fasta.out)
	   nextstrain_tree(nextstrain_align.out)

	emit: 
	   nextstrain_tree.out

}
