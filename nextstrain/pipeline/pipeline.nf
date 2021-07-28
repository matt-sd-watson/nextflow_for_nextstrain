#!/usr/bin/env nextflow

nextflow.enable.dsl=2

def splitUnderscore (string) { string.split('_')[0] }

process nextstrain_filter {


	publishDir path: "${params.output_dir}/${splitUnderscore(renamed_fasta.baseName)}/", mode: "copy"
	input: 
	file renamed_fasta

	output: 
	file "${splitUnderscore(renamed_fasta.baseName)}_filtered.fasta"

	script: 
	"""
	augur filter --sequences ${renamed_fasta} --metadata ${params.output_dir}/${splitUnderscore(renamed_fasta.baseName)}/${splitUnderscore(renamed_fasta.baseName)}.csv \
        --output ${splitUnderscore(renamed_fasta.baseName)}_filtered.fasta --min-date 2020
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

process nextstrain_tree_refine {

	label 'med_mem'

	publishDir path: "${params.output_dir}/${splitUnderscore(tree.baseName)}/", mode: "copy"

	input: 
	file tree
	
	output: 
	file "${splitUnderscore(tree.baseName)}_tree_refined.nwk"

	script:
	"""
	augur refine \
  	--tree ${tree} \
  	--alignment ${params.output_dir}/${splitUnderscore(tree.baseName)}/${splitUnderscore(tree.baseName)}_aln.fasta \
  	--metadata ${params.output_dir}/${splitUnderscore(tree.baseName)}/${splitUnderscore(tree.baseName)}.csv \
  	--output-tree ${splitUnderscore(tree.baseName)}_tree_refined.nwk \
  	--output-node-data ${params.output_dir}/${splitUnderscore(tree.baseName)}/${splitUnderscore(tree.baseName)}_branch_lengths.json \
  	--timetree \
  	--coalescent opt \
  	--date-confidence \
  	--date-inference marginal \
  	--clock-filter-iqd ${params.clockfilteriqd} \
	--seed ${params.refineseed} \
  	--keep-root > ${params.output_dir}/${splitUnderscore(tree.baseName)}/augur_refine_${splitUnderscore(tree.baseName)}_clock_${params.clockfilteriqd}.txt
	"""	

}

process nextstrain_tree_refine_clock_iterations {

	label 'med_mem'

	publishDir path: "${params.output_dir}/${splitUnderscore(tree.baseName)}/", mode: "copy"

	input: 
	file tree
	each clock
	
	output: 
	path "${splitUnderscore(tree.baseName)}_tree_refined_${clock}.nwk", emit: refined_tree
	val "${params.output_dir}/${splitUnderscore(tree.baseName)}/", emit: final_directories

	script:
	"""
	augur refine \
  	--tree ${tree} \
  	--alignment ${params.output_dir}/${splitUnderscore(tree.baseName)}/${splitUnderscore(tree.baseName)}_aln.fasta \
  	--metadata ${params.output_dir}/${splitUnderscore(tree.baseName)}/${splitUnderscore(tree.baseName)}.csv \
  	--output-tree ${splitUnderscore(tree.baseName)}_tree_refined_${clock}.nwk \
  	--output-node-data ${params.output_dir}/${splitUnderscore(tree.baseName)}/${splitUnderscore(tree.baseName)}_branch_lengths_${clock}.json \
  	--timetree \
  	--coalescent opt \
  	--date-confidence \
  	--date-inference marginal \
  	--clock-filter-iqd ${clock} \
	--seed ${params.refineseed} \
  	--keep-root > ${params.output_dir}/${splitUnderscore(tree.baseName)}/augur_refine_${splitUnderscore(tree.baseName)}_clock_${clock}.txt
	"""	

}

process nextstrain_traits {

	publishDir path: "${params.output_dir}/${splitUnderscore(refined_tree.baseName)}/", mode: "copy"

	input: 
	file refined_tree

	output: 
	file "${splitUnderscore(refined_tree.baseName)}_traits.json"

	script:
	"""
	augur traits --tree ${refined_tree} --metadata ${params.output_dir}/${splitUnderscore(refined_tree.baseName)}/${splitUnderscore(refined_tree.baseName)}.csv \
	--output-node-data ${splitUnderscore(refined_tree.baseName)}_traits.json --columns Health.Region
	"""
	

}

process nextstrain_ancestral {

	publishDir path: "${params.output_dir}/${splitUnderscore(refined_tree.baseName)}/", mode: "copy"

	input: 
	file refined_tree

	output: 
	file "${splitUnderscore(refined_tree.baseName)}_nt_muts.json"

	script:
	"""
	augur ancestral   --tree ${refined_tree}   --alignment ${params.output_dir}/${splitUnderscore(refined_tree.baseName)}/${splitUnderscore(refined_tree.baseName)}_aln.fasta \
	--output-node-data ${splitUnderscore(refined_tree.baseName)}_nt_muts.json   --inference joint
	"""

}

process nextstrain_translate {

	publishDir path: "${params.output_dir}/${splitUnderscore(nucleotide_json.baseName)}/", mode: "copy"

	input: 
	file nucleotide_json

	output: 
	file "${splitUnderscore(nucleotide_json.baseName)}_aa_muts.json"

	script:
	"""
	augur translate --tree ${params.output_dir}/${splitUnderscore(nucleotide_json.baseName)}/${splitUnderscore(nucleotide_json.baseName)}_tree_refined.nwk \
	--ancestral-sequences ${nucleotide_json} \
  	--reference-sequence ${params.alignment_ref} \
	--output-node-data ${splitUnderscore(nucleotide_json.baseName)}_aa_muts.json
	"""
}

process nextstrain_clades {

	publishDir path: "${params.output_dir}/${splitUnderscore(amino_acid_json.baseName)}/", mode: "copy"

	input: 
	file amino_acid_json

	output: 
	path "${splitUnderscore(amino_acid_json.baseName)}_clades.json"
	

	script:
	"""
	augur clades --tree ${params.output_dir}/${splitUnderscore(amino_acid_json.baseName)}/${splitUnderscore(amino_acid_json.baseName)}_tree_refined.nwk \
	--mutations ${params.output_dir}/${splitUnderscore(amino_acid_json.baseName)}/${splitUnderscore(amino_acid_json.baseName)}_nt_muts.json ${amino_acid_json} \
	--clades ${params.clades} --output-node-data ${splitUnderscore(amino_acid_json.baseName)}_clades.json
	"""

}

process nextstrain_export {

	publishDir path: "${params.output_dir}/all/", mode: "copy"

	input: 
	file clades

	output: 
	path "${splitUnderscore(clades.baseName)}_ncov.json", emit: final_json
	val "${params.output_dir}/${splitUnderscore(clades.baseName)}/", emit: final_dirs

	script:
	"""
	mkdir -p ${params.output_dir}/all/
	augur export v2   --tree ${params.output_dir}/${splitUnderscore(clades.baseName)}/${splitUnderscore(clades.baseName)}_tree_refined.nwk \
	--metadata ${params.output_dir}/${splitUnderscore(clades.baseName)}/${splitUnderscore(clades.baseName)}.csv \
	--node-data ${params.output_dir}/${splitUnderscore(clades.baseName)}/${splitUnderscore(clades.baseName)}_branch_lengths.json \
                    ${params.output_dir}/${splitUnderscore(clades.baseName)}/${splitUnderscore(clades.baseName)}_traits.json \
		    ${params.output_dir}/${splitUnderscore(clades.baseName)}/${splitUnderscore(clades.baseName)}_nt_muts.json \
		    ${params.output_dir}/${splitUnderscore(clades.baseName)}/${splitUnderscore(clades.baseName)}_aa_muts.json \
		    ${params.output_dir}/${splitUnderscore(clades.baseName)}/${splitUnderscore(clades.baseName)}_clades.json \
	--colors ${params.colortsv} \
	--auspice-config ${params.config} \
   	--output ${splitUnderscore(clades.baseName)}_ncov.json \
	--lat-longs ${params.latlong}
	"""

}

