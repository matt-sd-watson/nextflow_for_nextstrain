#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

binDir = Paths.get(workflow.projectDir.toString(), "bin")


process create_subset {

	publishDir = "${params.output_dir}/metadata/"

	input: 
	val metadata
	val rep
	
	output:
	path "rep_${rep}.csv"

	script: 
	"""
	mkdir -p ${params.output_dir}

	Rscript $binDir/process_metadata_nextstrain.R --input_metadata ${metadata} --output_file rep_${rep}.csv --subset_number ${params.subset_number} --rep ${rep}
	"""
	
}


process create_fasta {

	publishDir = "${params.output_dir}/fasta/"

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

	publishDir = "${params.output_dir}/renamed_fasta/"

	input: 
	file fasta

	output: 
	file "${fasta.simpleName}_renamed_Nextstrain.fa"

	script: 
	"""
	mkdir -p ${params.output_dir}/renamed_fasta/
	python $binDir/prepare_multifasta_Nextstrain.py -i ${fasta} -s ${params.output_dir}/metadata/${fasta.simpleName}.csv -o . -c Nextstrain
	"""
}

process nextstrain_filter {


	publishDir = "${params.output_dir}/filtered_fasta/"

	input:
	file renamed_fasta

	output: 
	file "${split_name}_filtered.fasta"

	script: 
	split_name = renamed_fasta.name.split('_renamed')[0]
	"""
	mkdir -p ${params.output_dir}/filtered_fasta/
	augur filter --sequences ${renamed_fasta} --metadata ${params.output_dir}/metadata/${split_name}.csv --output ${split_name}_filtered.fasta --min-date 2020
	"""
}


process nextstrain_align {

	// publish to multiple output directories, one for each alignment
	publishDir path: "${params.output_dir}/align/${filtered_fasta.simpleName}"

	input: 
	file filtered_fasta
	
	output: 
	file "${filtered_fasta.simpleName}_aln.fasta"

	script: 
	"""
	mkdir -p ${params.output_dir}/align/
	augur align --sequences ${filtered_fasta} --reference-sequence ${params.alignment_ref} --output ${filtered_fasta.simpleName}_aln.fasta --nthreads auto --fill-gaps
	"""
}


workflow {
	
	// need to fix the python renaming script to be able to handle strings
	iterations = Channel.of( 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 )
	metadata_file = params.metadata
	main: 
           create_subset(metadata_file, iterations)
           create_fasta(create_subset.out)
	   rename_headers(create_fasta.out)
	   nextstrain_filter(rename_headers.out)
	   nextstrain_align(nextstrain_filter.out)

}




