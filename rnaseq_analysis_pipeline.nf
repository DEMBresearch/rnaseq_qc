#!/usr/bin nextflow
project_dir = projectDir


//General input files locations
params.raw_reads = "$project_dir"
params.bwa_reference = "$project_dir/bwa_reference"
params.gff = "$project_dir/bwa_reference/reference.gff3"

//Process-specific output locations
params.fastqc_pre_fastp_outputdir = "$project_dir/output/fastqc_pre"
params.fastp_outputdir = "$project_dir/output/fastp"
params.fastqc_post_fastp_outputdir = "$project_dir/output/fastqc_post_fastp"
params.bwamem_outputdir = "$project_dir/output/bwamem_alignments"
params.bwamem_index = "$project_dir/output/bwamem_index"
params.spades_outputdir = "$project_dir/output/spades"
params.rnaQUAST_outdir = "$project_dir/output/rnaQUAST"
params.transcripts = "$project_dir/output/transcripts"


//Input read pairs
reads_pair_fastqc_pre = Channel.fromFilePairs("${params.raw_reads}/*[1,2].fastq.gz")
reads_pair_fastp = Channel.fromFilePairs("${params.raw_reads}/*[1,2].fastq.gz")
params.ref = "$project_dir/bwa_reference/reference.fna"
fasta_ref = file(params.ref)
gff_ref = file(params.gff)
reads_pair_index = Channel.fromFilePairs("${params.raw_reads}/*[1,2].fastq.gz")



//Resource defaults
params.threads = 10
params.memory = 30


process fastqc_pre_fastp {
    cpus = params.threads

    input:
        set sample, file(in_fastq) from reads_pair_fastqc_pre

    """
    mkdir -p "${params.fastqc_pre_fastp_outputdir}/${sample}"
    fastqc -t ${task.cpus} --noextract --outdir "${params.fastqc_pre_fastp_outputdir}/${sample}" ${in_fastq.get(0)} ${in_fastq.get(1)}
    """
}

process fastp {
    publishDir "${params.fastp_outputdir}/${sample}", pattern: "*", mode: "copy"
    cpus = params.threads
    input:
        set sample, file(in_fastq) from reads_pair_fastp

    output:
        set sample, "${sample}_fastp_*.fastq.gz" into fastp_out_ch_fastqc
        set sample, "${sample}_fastp_*.fastq.gz" into fastp_out_ch_map
        set sample, "${sample}_fastp_*.fastq.gz" into fastp_out_ch_spades
        file "*report*"


    """
    fastp -i "${in_fastq.get(0)}" \
	-o "${sample}_fastp_1.fastq.gz" \
	-I "${in_fastq.get(1)}" \
	-O "${sample}_fastp_2.fastq.gz" \
	-h "fastp_report.html" \
	-j "fastp_report.json" \
	--verbose --correction --dont_overwrite --detect_adapter_for_pe -w ${task.cpus}
    """
}

process fastqc_post_fastp {
    cpus = params.threads

    input:
        set sample, file(in_fastp) from fastp_out_ch_fastqc

    """
    mkdir -p "${params.fastqc_post_fastp_outputdir}/${sample}"
    fastqc -t ${task.cpus} --noextract --outdir "${params.fastqc_post_fastp_outputdir}/${sample}" "${in_fastp.get(0)}" "${in_fastp.get(1)}"
    """
}

process bwa_index {
    publishDir "${params.bwamem_index}", pattern: "*", mode: "copy"
    
    cpus = params.threads

    input:
        file fasta_ref

    output:
        file "*" into bwa_index_ch

    """
    bwa index "${fasta_ref}" -p "index"
    """
}



process bwa_mem {
    //publishDir "${params.bwamem_outputdir}/${sample}", pattern: "*", mode: "copy"
    
    cpus = params.threads

    input:
        set sample, file(in_fastp) from fastp_out_ch_map
        file "*" from bwa_index_ch
        file fasta_ref

    output:
        set sample, file("${sample}.sam") into bwa_mem_out_ch

    """
    bwa mem "index" "${in_fastp.get(0)}" "${in_fastp.get(1)}" -t ${task.cpus} > "${sample}.sam"
    """
}

process samtools_get_bam {
    publishDir "${params.bwamem_outputdir}/${sample}", pattern: "*_sorted.bam*", mode: "copy"
    
    cpus = params.threads

    input:
        set sample, file(in_sam) from bwa_mem_out_ch
        
    output:
        set sample, file("${sample}_sorted.bam") into bam_out_ch

    """
    samtools view -S --threads ${task.cpus} -b "${in_sam}" > "${sample}.bam"
    samtools sort "${sample}.bam" -o "${sample}_sorted.bam" --threads ${task.cpus}
    
    """
}

process samtools_get_flagstat {
    publishDir "${params.bwamem_outputdir}/${sample}", pattern: "*.txt", mode: "copy"
    
    cpus = params.threads

    input:
        set sample, file(sorted_bam) from bam_out_ch

    """
    samtools flagstat --threads ${task.cpus} "${sorted_bam}" > "${sample}.flagstat.txt"
    """
}

process rna_spades_assembly {
    publishDir "${params.spades_outputdir}/${sample}", pattern: "*", mode: "copy"
    
    
    cpus = params.threads

    input:
        set sample, file(in_spades) from fastp_out_ch_spades

    output:
        path "transcripts.fasta" into spades_out_ch


    """
    rnaspades.py -t ${task.cpus} -m ${params.memory} -1 "${in_spades.get(0)}" -2 "${in_spades.get(1)}" -o spades_out
    mv spades_out/transcripts.fasta ${sample}_transcripts.fasta
    cp ${sample}_transcripts.fasta ${params.transcripts}/${sample}_transcripts.fasta
    """
}

process rna_quast {
    publishDir "${params.rnaQUAST_outdir}/${sample}", pattern: "*", mode: "copy"

    input:
        file transcripts from spades_out_ch.collect()
        file gff_ref
        file fasta_ref

    output:
    file "*"

    """
    rnaQUAST.py --transcripts "${params.transcripts}/*.fasta" --reference ${fasta_ref} --gtf ${gff_ref} --blat --prokaryote -o ${params.rnaQUAST_outdir} --busco ${params.busco_lineage} -t 1
    """
}
