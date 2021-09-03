#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

binDir = Paths.get(workflow.projectDir.toString(), "bin/")


process create_subset {

	publishDir path: "${params.output_dir}/${category}/", mode: "copy"

	input: 
	val category
	
	output:
	tuple val(category), path("${category}.csv"), emit: metadata

	script: 
	"""
	Rscript $binDir/process_metadata_nextstrain.R --input_metadata ${params.metadata} --output_file ${category}.csv --subset_number ${params.subset_number} --category ${category}
	"""
	
}

process create_subset_by_lineage {

	publishDir path: "${params.output_dir}/${lineage}/", mode: "copy"

	input: 
	val lineage	

	output:
	tuple val(lineage), path("${lineage}.csv"), emit: lineage

	script: 
	"""
	Rscript $binDir/make_nextstrain_subsets_by_lineage.R --input_lineage ${params.lineage_report} --lineage_id ${lineage} --input_metadata ${params.metadata}
	"""
		

}


process create_fasta {

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"

	input: 
	tuple val(cat_name), path(metadata_sheet)

	output: 
	tuple val(cat_name), path("${cat_name}.fa"), emit: fasta

	script: 
	"""
	cut -d, -f1 ${metadata_sheet} > names_${cat_name}.txt
	fastafurious subset -f ${params.master_fasta} -l names_${cat_name}.txt -o ${cat_name}.fa && rm names_${cat_name}.txt
	"""
}


process rename_headers {

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"

	input: 
	tuple val(cat_name), path(metadata), path(fasta)

	output: 
	tuple val(cat_name), path("${cat_name}_renamed_Nextstrain.fa"), emit: renamed

	script: 
	"""
	python $binDir/prepare_multifasta_Nextstrain.py -i ${fasta} -s ${metadata} -o . -c Nextstrain
	"""
}




