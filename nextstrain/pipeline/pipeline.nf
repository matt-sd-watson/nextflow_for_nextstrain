#!/usr/bin/env nextflow

nextflow.enable.dsl=2

def splitUnderscore (string) { string.split('_')[0] }

process nextstrain_filter {

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"
	
	input: 
	tuple val(cat_name), path(metadata), path(renamed_fasta)

	output: 
	tuple val(cat_name), path("${cat_name}_filtered.fasta"), emit: filtered

	script: 
	"""
	augur filter --sequences ${renamed_fasta} --metadata ${metadata} \
        --output ${cat_name}_filtered.fasta --min-date 2020
	"""
}


process nextstrain_align {

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"

	input: 
	tuple val(cat_name), path(filtered_fasta)
	
	output: 
	tuple val(cat_name), path("${cat_name}_aln.fasta"), emit: alignment

	script:
	"""
	augur align --sequences ${filtered_fasta} --reference-sequence ${params.alignment_ref} --output ${cat_name}_aln.fasta --nthreads ${params.threads} --fill-gaps
	"""
}

process nextstrain_tree {

	label 'med_mem'

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"

	input: 
	tuple val(cat_name), path(alignment)
	
	output: 
	tuple val(cat_name), path("${cat_name}_tree.nwk"), emit: tree

	script:
	"""
	augur tree --alignment ${alignment} --output ${cat_name}_tree.nwk --nthreads ${params.threads}
	"""	

}

process nextstrain_tree_refine {

	label 'med_mem'

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"

	input: 
	tuple val(cat_name), path(tree), path(metadata), path(alignment)
	
	output: 
	tuple val(cat_name), path("${cat_name}_tree_refined.nwk"), path("${cat_name}_branch_lengths.json"), emit: refined

	script:
	"""
	augur refine \
  	--tree ${tree} \
  	--alignment ${alignment} \
  	--metadata ${metadata} \
  	--output-tree ${cat_name}_tree_refined.nwk \
  	--output-node-data ${cat_name}_branch_lengths.json \
  	--timetree \
  	--coalescent opt \
  	--date-confidence \
  	--date-inference marginal \
  	--clock-filter-iqd ${params.clockfilteriqd} \
	--seed ${params.refineseed} \
  	--keep-root > ${params.output_dir}/${cat_name}/augur_refine_${cat_name}_clock_${params.clockfilteriqd}.txt
	"""	

}

process nextstrain_tree_refine_clock_iterations {

	label 'med_mem'

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"

	input: 
	tuple val(cat_name), path(tree), path(metadata), path(alignment)
	each clock
	
	output: 
	tuple val(cat_name), path("${cat_name}_tree_refined_clock{clock}.nwk"), emit: refined_tree
	val "${params.output_dir}/${cat_name}/", emit: final_directories

	script:
	"""
	augur refine \
  	--tree ${tree} \
  	--alignment ${alignment} \
  	--metadata ${metadata} \
  	--output-tree ${cat_name}_tree_refined_clock{clock}.nwk \
  	--output-node-data ${cat_name}_clock_{clock}_branch_lengths.json \
  	--timetree \
  	--coalescent opt \
  	--date-confidence \
  	--date-inference marginal \
  	--clock-filter-iqd ${clock} \
	--seed ${params.refineseed} \
  	--keep-root > ${params.output_dir}/${cat_name}/augur_refine_${cat_name}_clock_${clock}.txt
	"""

}

process nextstrain_traits {

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"

	input: 
	tuple val(cat_name), path(metadata), path(refined_tree), path(branch_lengths)

	output: 
	tuple val(cat_name), path("${cat_name}_traits.json"), emit: traits

	script:
	"""
	augur traits --tree ${refined_tree} --metadata ${metadata} \
	--output-node-data ${cat_name}_traits.json --columns Health.Region
	"""
	

}

process nextstrain_ancestral {

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"

	input: 
	tuple val(cat_name), path(alignment), path(refined_tree), path(branch_lengths)

	output: 
	tuple val(cat_name), path("${cat_name}_nt_muts.json"), emit: ancestral

	script:
	"""
	augur ancestral   --tree ${refined_tree}   --alignment ${alignment} \
	--output-node-data ${splitUnderscore(refined_tree.baseName)}_nt_muts.json   --inference joint
	"""

}

process nextstrain_translate {

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"

	input:
	tuple val(cat_name), path(refined_tree), path(branch_lengths), path(nucleotide_json)

	output: 
	tuple val(cat_name), path("${cat_name}_aa_muts.json"), emit: translation

	script:
	"""
	augur translate --tree ${refined_tree} \
	--ancestral-sequences ${nucleotide_json} \
  	--reference-sequence ${params.alignment_ref} \
	--output-node-data ${cat_name}_aa_muts.json
	"""
}

process nextstrain_clades {

	publishDir path: "${params.output_dir}/${cat_name}/", mode: "copy"

	input: 
	tuple val(cat_name), path(refined_tree), path(branch_lengths), path(nucleotide_json), path(amino_acid_json)

	output: 
	tuple val(cat_name), path("${cat_name}_clades.json"), emit: clades
	

	script:
	"""
	augur clades --tree ${refined_tree} \
	--mutations ${nucleotide_json} ${amino_acid_json} \
	--clades ${params.clades} --output-node-data ${cat_name}_clades.json
	"""

}

process nextstrain_export {

	publishDir path: "${params.output_dir}/all/", mode: "copy"

	input: 
	tuple val(cat_name), path(tree), path(metadata), path(alignment), path(refined_tree), path(branch_lengths), path(nucleotide_json), path(amino_acid_json), path(traits), path(clade_json)

	output: 
	tuple val(cat_name), path("${cat_name}_ncov.json"), emit: export_json

	script:
	"""
	mkdir -p ${params.output_dir}/all/
	augur export v2   --tree ${refined_tree} \
	--metadata ${metadata} \
	--node-data ${branch_lengths} \
                    ${traits} \
		    ${nucleotide_json} \
		    ${amino_acid_json} \
		    ${clade_json} \
	--colors ${params.colortsv} \
	--auspice-config ${params.config} \
   	--output ${cat_name}_ncov.json \
	--lat-longs ${params.latlong}
	"""

}

