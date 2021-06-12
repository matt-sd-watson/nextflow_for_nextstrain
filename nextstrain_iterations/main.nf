#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

binDir = Paths.get(workflow.projectDir.toString(), "bin")


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

process nextstrain_filter {


	publishDir path: "${params.output_dir}/${split_name}/", mode: "copy"
	input: 
	file renamed_fasta

	output: 
	file "${split_name}_filtered.fasta"

	script: 
	split_name = renamed_fasta.name.split('_renamed')[0]
	"""
	augur filter --sequences ${renamed_fasta} --metadata ${params.output_dir}/${split_name}/${split_name}.csv --output ${split_name}_filtered.fasta --min-date 2020
	"""
}


process nextstrain_align {

	publishDir path: "${params.output_dir}/${split_name_align}/", mode: "copy"

	input: 
	file filtered_fasta
	
	output: 
	file "${split_name_align}_aln.fasta"

	script:
	split_name_align = filtered_fasta.simpleName.split('_filtered')[0]
	"""
	augur align --sequences ${filtered_fasta} --reference-sequence ${params.alignment_ref} --output ${split_name_align}_aln.fasta --nthreads auto --fill-gaps
	"""
}

process nextstrain_tree {

	publishDir path: "${params.output_dir}/${split_name_tree}/", mode: "copy"

	input: 
	file alignment
	
	output: 
	file "${split_name_tree}_tree.nwk"

	script:
	split_name_tree = alignment.simpleName.split('_aln')[0]
	"""
	augur tree --alignment ${alignment} --output ${split_name_tree}_tree.nwk --nthreads auto
	"""	

}

process nextstrain_tree_refine {

	publishDir path: "${params.output_dir}/${split_name_tree}/", mode: "copy"

	input: 
	file tree
	
	output: 
	file "${split_name_tree}_tree_refined.nwk"

	script:
	split_name_tree = tree.simpleName.split('_tree')[0]
	"""
	augur refine \
  	--tree ${tree} \
  	--alignment ${params.output_dir}/${split_name_tree}/${split_name_tree}_aln.fasta \
  	--metadata ${params.output_dir}/${split_name_tree}/${split_name_tree}.csv \
  	--output-tree ${split_name_tree}_tree_refined.nwk \
  	--output-node-data ${params.output_dir}/${split_name_tree}/${split_name_tree}_branch_lengths.json \
  	--timetree \
  	--coalescent opt \
  	--date-confidence \
  	--date-inference marginal \
  	--clock-filter-iqd ${params.clockfilteriqd} \
  	--keep-root
	"""	

}

process nextstrain_traits {

	publishDir path: "${params.output_dir}/${split_name_tree}/", mode: "copy"

	input: 
	file refined_tree

	output: 
	file "${split_name_tree}_traits.json"

	script:
	split_name_tree = refined_tree.simpleName.split('_tree')[0]
	"""
	augur traits --tree ${refined_tree} --metadata ${params.output_dir}/${split_name_tree}/${split_name_tree}.csv \
	--output-node-data ${split_name_tree}_traits.json --columns Health.Region
	"""
	

}

process nextstrain_ancestral {

	publishDir path: "${params.output_dir}/${split_name_tree}/", mode: "copy"

	input: 
	file refined_tree

	output: 
	file "${split_name_tree}_nt_muts.json"

	script:
	split_name_tree = refined_tree.simpleName.split('_tree')[0]
	"""
	augur ancestral   --tree ${refined_tree}   --alignment ${params.output_dir}/${split_name_tree}/${split_name_tree}_aln.fasta \
	--output-node-data ${split_name_tree}_nt_muts.json   --inference joint
	"""

}

process nextstrain_translate {

	publishDir path: "${params.output_dir}/${split_name_nuc}/", mode: "copy"

	input: 
	file nucleotide_json

	output: 
	file "${split_name_nuc}_aa_muts.json"

	script:
	split_name_nuc = nucleotide_json.simpleName.split('_nt_muts')[0]
	"""
	augur translate --tree ${params.output_dir}/${split_name_nuc}/${split_name_nuc}_tree_refined.nwk \
	--ancestral-sequences ${nucleotide_json} \
  	--reference-sequence ${params.alignment_ref} \
	--output-node-data ${split_name_nuc}_aa_muts.json
	"""
}

process nextstrain_clades {

	publishDir path: "${params.output_dir}/${split_name_aa}/", mode: "copy"

	input: 
	file amino_acid_json

	output: 
	file "${split_name_aa}_clades.json"

	script:
	split_name_aa = amino_acid_json.simpleName.split('_aa_muts')[0]
	"""
	augur clades --tree ${params.output_dir}/${split_name_aa}/${split_name_aa}_tree_refined.nwk \
	--mutations ${params.output_dir}/${split_name_aa}/${split_name_aa}_nt_muts.json ${amino_acid_json} \
	--clades ${params.clades} --output-node-data ${split_name_aa}_clades.json
	"""

}

process nextstrain_export {

	publishDir path: "${params.output_dir}/all/", mode: "copy"

	input: 
	file clades

	output: 
	file "${split_name_clades}_ncov.json"

	script:
	split_name_clades = clades.simpleName.split('_clades')[0]
	"""
	mkdir -p ${params.output_dir}/all/
	augur export v2   --tree ${params.output_dir}/${split_name_clades}/${split_name_clades}_tree_refined.nwk \
	--metadata ${params.output_dir}/${split_name_clades}/${split_name_clades}.csv \
	--node-data ${params.output_dir}/${split_name_clades}/${split_name_clades}_branch_lengths.json \
                    ${params.output_dir}/${split_name_clades}/${split_name_clades}_traits.json \
		    ${params.output_dir}/${split_name_clades}/${split_name_clades}_nt_muts.json \
		    ${params.output_dir}/${split_name_clades}/${split_name_clades}_aa_muts.json \
		    ${params.output_dir}/${split_name_clades}/${split_name_clades}_clades.json \
	--colors ${params.colortsv} \
	--auspice-config ${params.config} \
   	--output ${split_name_clades}_ncov.json \
	--lat-longs ${params.latlong}
	"""

}


workflow {
	
	// need to fix the python renaming script to be able to handle strings
	iterations = Channel.of( 1, 2 )
	metadata_file = params.metadata
	main: 
           create_subset(metadata_file, iterations)
           create_fasta(create_subset.out)
	   rename_headers(create_fasta.out)
	   nextstrain_filter(rename_headers.out)
	   nextstrain_align(nextstrain_filter.out)
	   nextstrain_tree(nextstrain_align.out)
	   nextstrain_tree_refine(nextstrain_tree.out)
	   nextstrain_traits(nextstrain_tree_refine.out)
	   nextstrain_ancestral(nextstrain_tree_refine.out)
	   nextstrain_translate(nextstrain_ancestral.out)
	   nextstrain_clades(nextstrain_translate.out)
	   nextstrain_export(nextstrain_clades.out)
	
}




