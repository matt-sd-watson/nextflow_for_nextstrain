#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

binDir = Paths.get(workflow.projectDir.toString(), "bin/")


process manipulate_json {

	publishDir path: "${params.output_dir}/all_edited/", mode: "copy"

	input: 
	tuple val(cat_name), path(original_json)
	
	output:
	path "${cat_name}_edited.json", emit: edited_json
	val "${params.output_dir}/${cat_name}/", emit: final_dirs

	script: 
	"""
	python $binDir/manipulate_ncov_json.py -i ${original_json} -o ${cat_name}_edited.json
	"""
	
}

// remove any unecessary files from generating test statistics
process clean_directories {


	input: 
	val location

	script: 
	"""
	sh $binDir/clean_directories.sh ${location}/ ${params.output_dir}
	"""
}




