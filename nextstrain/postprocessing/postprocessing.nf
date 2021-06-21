#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

binDir = Paths.get(workflow.projectDir.toString(), "bin/")


process manipulate_json {

	publishDir path: "${params.output_dir}/all_edited/", mode: "copy"

	input: 
	file original_json
	
	output:
	file "${original_json.baseName}_edited.json"

	script: 
	json_name = 
	"""
	python $binDir/manipulate_ncov_json.py -i ${original_json} --o ${original_json.baseName}_edited.json
	"""
	
}


