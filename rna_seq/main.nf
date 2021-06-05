
fastq_files = Channel.fromPath("${params.input_dir}/*.fastq.gz").into { datasets_fastqc; datasets_to_trim; datasets_to_align }

process fastqc {

	publishDir = "${params.out_dir}"

	input: 
	file input_fastq from datasets_fastqc

	script: 
	"""
	fastqc -t 5 ${input_fastq} -o ${params.out_dir}
	"""
}


adapter_seqs = Channel.fromPath("${params.adapter_csv}").splitCsv(header:true).map{row -> tuple(row.adapter, row.sample) }

process adapter_trim {
	
	publishDir = "${params.out_dir}"

	input: 
	set adapter, sample from adapter_seqs
	file untrimmed from datasets_to_trim

	output: 
	file "${untrimmed.simpleName}_adaptertrimmed.fastq.gz" into trimmed_seqs
	
	script: 
	"""
	cutadapt -q 20 -a ${adapter} -o ${params.star_out_dir}/${untrimmed.simpleName}_adaptertrimmed.fastq.gz ${untrimmed}
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
