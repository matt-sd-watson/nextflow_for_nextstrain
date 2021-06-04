
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

process star_align {

	publishDir = "${params.star_out_dir}"
	
	input: 
	file input_fastq from datasets_align

	script: 
	"""
	STAR --genomeDir /Users/mattsdwatson/star/index/vib_reference/ --readFilesIn ${input_fastq} \
	    --readFilesCommand gunzip -c --outSAMtype BAM SortedByCoordinate --outFileNamePrefix ${params.star_out_dir}/${input_fastq.simpleName}/${input_fastq.simpleName} \
   	 --alignIntronMin 50 --alignIntronMax 500000 \
    	--sjdbGTFfile /Users/mattsdwatson/star/index/vib_annotations/exp2323-genes.gtf \
    	--outSAMprimaryFlag OneBestScore --twopassMode Basic \
    	--outReadsUnmapped Fastx \
    	--seedSearchStartLmax 15  \
    	--outFilterScoreMinOverLread 0 --outFilterMatchNminOverLread 0  --outFilterMatchNmin 50
	"""
}		
