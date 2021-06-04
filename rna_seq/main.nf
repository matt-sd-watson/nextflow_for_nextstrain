nextflow.enable.dsl=2

fastq_files = Channel.fromPath("${params.input_dir}/*.fastq.gz").into { datasets_fastqc; datasets_align }

process fastqc {

	publishDir = "${params.out_dir}"

	input: 
	file input_fastq from datasets_fastqc

	script: 
	"""
	fastqc -t 5 ${input_fastq} -o ${params.out_dir}
	"""
}


adapter_seqs = Channel.fromPath(${params.adapter_csv}).splitCsv(header:true).map{row -> tuple(sample_id, adapter) }

process adapter_trim {

	input: 
	set sample_id, adapter from adapter_seqs


	output: 

	file "${sample_id}_adaptertrimmed.fastq.gz" into trimmed_seqs

	script: 
	"""
	cutadapt -q 20 -a ${adapter} -o ${params.star_out_dir}/${sample_id}_adaptertrimmed.fastq.gz
	"""
}


process star_align {

	publishDir = "${params.star_out_dir}"
	
	input: 
	file input_fastq from trimmed_seqs

	script: 
	"""
	STAR --genomeDir ${params.star_ref} --readFilesIn ${input_fastq} \
	    --readFilesCommand gunzip -c --outSAMtype BAM SortedByCoordinate --outFileNamePrefix ${params.star_out_dir}/${input_fastq.simpleName}/${input_fastq.simpleName} \
   	 --alignIntronMin ${params.alignIntronMin} --alignIntronMax ${params.alignIntronMax} \
    	--sjdbGTFfile ${params.star_gtf} \
    	--outSAMprimaryFlag OneBestScore --twopassMode Basic \
    	--outReadsUnmapped Fastx \
    	--seedSearchStartLmax ${params.seedSearchStartLmax}  \
    	--outFilterScoreMinOverLread ${params.outFilterScoreMinOverLread} --outFilterMatchNminOverLread ${params.outFilterMatchNminOverLread} \
	--outFilterMatchNmin ${params.outFilterMatchNmin}
	"""
}		
