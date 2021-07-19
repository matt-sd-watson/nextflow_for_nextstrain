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

process create_subset_by_lineage {

	publishDir path: "${params.output_dir}/${lineage}/", mode: "copy"

	input: 
	val lineage	

	output:
	path "${lineage}.csv"

	script: 
	"""
	Rscript $binDir/make_nextstrain_subsets_by_lineage.R --input_lineage ${params.lineage_report} --lineage_id ${lineage} --input_metadata ${params.metadata}
	"""
		

}





process create_fasta {

	publishDir path: "${params.output_dir}/${metadata_sheet.baseName}/", mode: "copy"

	input: 
	path metadata_sheet

	output: 
	file "${metadata_sheet.baseName}.fa"

	script: 
	"""
	cut -d, -f1 ${metadata_sheet} > names_${metadata_sheet.baseName}.txt
	$binDir/./faSomeRecords ${params.master_fasta} names_${metadata_sheet.baseName}.txt ${metadata_sheet.baseName}.fa && rm names_${metadata_sheet.baseName}.txt
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




