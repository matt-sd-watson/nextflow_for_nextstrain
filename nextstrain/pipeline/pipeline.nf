#!/usr/bin/env nextflow

nextflow.enable.dsl=2

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
	split_name_align = filtered_fasta.baseName.split('_filtered')[0]
	"""
	augur align --sequences ${filtered_fasta} --reference-sequence ${params.alignment_ref} --output ${split_name_align}_aln.fasta --nthreads ${params.threads} --fill-gaps
	"""
}

process nextstrain_tree {

	publishDir path: "${params.output_dir}/${split_name_tree}/", mode: "copy"

	input: 
	file alignment
	
	output: 
	file "${split_name_tree}_tree.nwk"

	script:
	split_name_tree = alignment.baseName.split('_aln')[0]
	"""
	augur tree --alignment ${alignment} --output ${split_name_tree}_tree.nwk --nthreads ${params.threads}
	"""	

}

process nextstrain_tree_refine {

	publishDir path: "${params.output_dir}/${split_name_tree}/", mode: "copy"

	input: 
	file tree
	
	output: 
	file "${split_name_tree}_tree_refined.nwk"

	script:
	split_name_tree = tree.baseName.split('_tree')[0]
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

process nextstrain_tree_refine_clock_iterations {

	publishDir path: "${params.output_dir}/${split_name_tree}/", mode: "copy"

	input: 
	file tree
	each clock
	
	output: 
	file "${split_name_tree}_tree_refined_${clock}.nwk"

	script:
	split_name_tree = tree.baseName.split('_tree')[0]
	"""
	augur refine \
  	--tree ${tree} \
  	--alignment ${params.output_dir}/${split_name_tree}/${split_name_tree}_aln.fasta \
  	--metadata ${params.output_dir}/${split_name_tree}/${split_name_tree}.csv \
  	--output-tree ${split_name_tree}_tree_refined_${clock}.nwk \
  	--output-node-data ${params.output_dir}/${split_name_tree}/${split_name_tree}_branch_lengths_${clock}.json \
  	--timetree \
  	--coalescent opt \
  	--date-confidence \
  	--date-inference marginal \
  	--clock-filter-iqd ${clock} \
  	--keep-root > ${params.output_dir}/${split_name_tree}/augur_refine_${split_name_tree}_clock_${clock}.txt
	"""	

}

process nextstrain_traits {

	publishDir path: "${params.output_dir}/${split_name_tree}/", mode: "copy"

	input: 
	file refined_tree

	output: 
	file "${split_name_tree}_traits.json"

	script:
	split_name_tree = refined_tree.baseName.split('_tree')[0]
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
	split_name_tree = refined_tree.baseName.split('_tree')[0]
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
	split_name_nuc = nucleotide_json.baseName.split('_nt_muts')[0]
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
	split_name_aa = amino_acid_json.baseName.split('_aa_muts')[0]
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
	split_name_clades = clades.baseName.split('_clades')[0]
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

