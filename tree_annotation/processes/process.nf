#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

binDir = Paths.get(workflow.projectDir.toString(), "bin/")


def splitUnderscore (string) { string.split('_')[0] }


process create_subset_by_lineage {

	publishDir path: "${params.output_dir}/${lineage}/", mode: "copy"

	input: 
	val lineage	

	output:
	path "${lineage}.txt"

	script: 
	"""
	Rscript $binDir/make_nextstrain_subsets_by_lineage.R --input_lineage ${params.lineage_report} --lineage_id ${lineage}
	"""
		

}

process create_fasta {

	publishDir path: "${params.output_dir}/${lineage_list.baseName}/", mode: "copy"

	input: 
	path lineage_list

	output: 
	file "${lineage_list.baseName}.fa"

	script: 
	"""
	$binDir/./faSomeRecords ${params.master_fasta} ${lineage_list} ${lineage_list.baseName}.fa
	"""
}

process rename_headers {

	publishDir path: "${params.output_dir}/${fasta.baseName}/", mode: "copy"

	input: 
	file fasta

	output: 
	file "${fasta.baseName}_renamed_Nextstrain.fa"

	script: 
	"""
	python $binDir/prepare_multifasta_Nextstrain.py -i ${fasta} -s ${params.output_dir}/${fasta.baseName}/${fasta.baseName}.csv -o . -c Nextstrain
	"""
}

process nextstrain_align {

	publishDir path: "${params.output_dir}/${splitUnderscore(filtered_fasta.baseName)}/", mode: "copy"

	input: 
	file filtered_fasta
	
	output: 
	file "${splitUnderscore(filtered_fasta.baseName)}_aln.fasta"

	script:
	"""
	augur align --sequences ${filtered_fasta} --reference-sequence ${params.alignment_ref} --output ${splitUnderscore(filtered_fasta.baseName)}_aln.fasta --nthreads ${params.threads} --fill-gaps
	"""
}

process nextstrain_tree {

	label 'med_mem'

	publishDir path: "${params.output_dir}/${splitUnderscore(alignment.baseName)}/", mode: "copy"

	input: 
	file alignment
	
	output: 
	file "${splitUnderscore(alignment.baseName)}_tree.nwk"

	script:
	"""
	augur tree --alignment ${alignment} --output ${splitUnderscore(alignment.baseName)}_tree.nwk --nthreads ${params.threads}
	"""	

}
