# RNA-seq Quality Check


## Basic RNA-seq genomic data QC pipeline

The pipeline is written in NextFlow. It uses the following programs:
- fastp (https://github.com/OpenGene/fastp)
- FASTQC (https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- bwa mem (https://github.com/lh3/bwa)
- rnaSPAdes (https://cab.spbu.ru/software/spades/)
- rnaQUAST (https://github.com/ablab/rnaquast)
- BLAT (https://github.com/djhshih/blat)
- BUSCO (https://gitlab.com/ezlab/busco/-/releases#5.1.2)
- samtools (https://github.com/samtools/samtools/)

Use docker for running the pipeline


## Pipeline stages

1) FastQC before
2) Raw data filtering and trimming using fastp
3) FastQC after
4) Map reads after QC to reference genome to get basic mapping stats 
5) Assemble transcriptome with rnaSPAdes
6) Assess assembly with rnaQUAST with BUSCO

## Running the pipeline

To run the pipeline you will first need to create a docker image. You can create the image by downloading `Dockerfile` and `config.ini` files and placing them in one directory. Then, build the image with:
```
docker image build -t rnaseq-docker .
```

After that, you can run the pipeline using
```
nextflow run rnaseq_analysis_pipeline.nf
```

### Script parameters

All the parameters used in the scrips have defauls, but they can be customised using the following flags

```
//INPUT
--raw_reads - path to raw reads location (default: "./")
--gff - path to .gff file for bwamem (default: "./bwa_reference/reference.gff3")
--bwa_fasta - path to FASTA-format file for bwamem (default: "./bwa_reference/reference.fna")

//OUTPUT
--fastqc_pre_fastp_outputdir - path to pre-fastp fastQC output (default: "./output/fastqc_pre")
--fastp_outputdir - path to fastp output (default: "./output/fastp")
--fastqc_post_fastp_outputdir - path to post-fastp fastQC output (default: "./output/fastqc_post_fastp")
--bwamem_outputdir - path to bwamem output (default: "./output/bwamem_alignments")
--bwamem_index - path to bwamem-index output (default: "./output/bwamem_index")
--spades_outputdir - path to rnaSPAdes output (default: "./output/spades")
--rnaQUAST_outdir - path to rnaQUAST output (default: "./output/rnaQUAST")
--transcripts - path to transcripts extracted from rnaSPAdes output (default: "./output/transcripts")
```

## Authors

Karol Ciuchcinski (@Haelmorn) & Mikolaj Dziurzynski (@mdziurzynski)

## License
The software in this repository is put under an MIT licensing scheme - please see the [LICENSE] (https://github.com/DEMBresearch/rnaseq_qc/blob/main/LICENSE) file for more details.
