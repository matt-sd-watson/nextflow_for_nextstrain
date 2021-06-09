nextflow.enable.dsl=2

process fastqc {

	publishDir = "${params.out_dir}/"

	input: 
	file input_fastq

	script: 
	"""
	fastqc -t 5 ${input_fastq} -o ${params.out_dir}
	"""
}


process adapter_trim {
	
	publishDir = "${params.out_dir}/"

	input: 
	tuple val(adapter), val(sample_id)

	output: 

	file "${sample_id}_adaptertrimmed.fastq.gz"
	
	script: 
	"""
	cutadapt -q 20 -a ${adapter} -o ${sample_id}_adaptertrimmed.fastq.gz ${params.input_dir}/${sample_id}.fastq.gz
	"""
}

process star_align {

	publishDir = "${params.out_dir}/"
	
	input: 
	file trimmed_fastq

	script: 
	"""
	STAR --genomeDir ${params.star_ref} --readFilesIn ${trimmed_fastq} \
	    --readFilesCommand gunzip -c --outSAMtype BAM SortedByCoordinate --outFileNamePrefix ${params.out_dir}/${trimmed_fastq.simpleName}/${trimmed_fastq.simpleName} \
   	 --alignIntronMin ${params.alignIntronMin} --alignIntronMax ${params.alignIntronMax} \
    	--sjdbGTFfile ${params.star_gtf} \
    	--outSAMprimaryFlag OneBestScore --twopassMode Basic \
    	--outReadsUnmapped Fastx \
    	--seedSearchStartLmax ${params.seedSearchStartLmax}  \
    	--outFilterScoreMinOverLread ${params.outFilterScoreMinOverLread} --outFilterMatchNminOverLread ${params.outFilterMatchNminOverLread} \
	--outFilterMatchNmin ${params.outFilterMatchNmin}
	"""
}


workflow {

	fastq_files = Channel.fromPath("${params.input_dir}/*.fastq.gz")
	adapter_seqs = Channel.fromPath("${params.adapter_csv}").splitCsv(header:true).map{row -> tuple(row.adapter, row.sample_id) }
	main: 
	   fastqc(fastq_files)
	   adapter_trim(adapter_seqs)
	   star_align(adapter_trim.out)
}			
