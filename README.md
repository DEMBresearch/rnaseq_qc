# RNA-seq Quality Check


##Basic RNA-seq genomic data QC pipeline

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


## Authors

Karol Ciuchcinski & Mikolaj Dziurzynski

## License
The software in this repository is put under an MIT licensing scheme - please see the LICENSE file for more details.
