#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

binDir = Paths.get(workflow.projectDir.toString(), "bin/")


process create_subset {

	publishDir path: "${params.output_dir}/${category}/", mode: "copy"

	input: 
	val metadata
	val category
	
	output:
	path "${category}.csv"

	script: 
	"""
	Rscript $binDir/process_metadata_nextstrain.R --input_metadata ${metadata} --output_file ${category}.csv --subset_number ${params.subset_number} --category ${category}
	"""
	
}


process create_fasta {

	publishDir path: "${params.output_dir}/${metadata_sheet.simpleName}/", mode: "copy"

	input: 
	path metadata_sheet

	output: 
	file "${metadata_sheet.simpleName}.fa"

	script: 
	"""
	cut -d, -f1 ${metadata_sheet} > names_${metadata_sheet.simpleName}.txt
	$binDir/./faSomeRecords /NetDrive/Projects/COVID-19/Other/master_fasta/complete* names_${metadata_sheet.simpleName}.txt ${metadata_sheet.simpleName}.fa && rm names_${metadata_sheet.simpleName}.txt
	"""
}


process rename_headers {

	publishDir path: "${params.output_dir}/${fasta.simpleName}/", mode: "copy"

	input: 
	file fasta

	output: 
	file "${fasta.simpleName}_renamed_Nextstrain.fa"

	script: 
	"""
	python $binDir/prepare_multifasta_Nextstrain.py -i ${fasta} -s ${params.output_dir}/${fasta.simpleName}/${fasta.simpleName}.csv -o . -c Nextstrain
	"""
}

