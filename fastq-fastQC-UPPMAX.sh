#!/bin/bash
module load bioinfo-tools
module load samtools/1.9
module load FastQC/0.11.8
module load MultiQC/1.9

mkdir out/fastq
for file in out/Output_bam/*.output.bam; do name=$(basename $file .output.bam); samtools fastq -F 256 -F 1024 $file | pigz -c > out/fastq/$name.fq.gz; done

mkdir out/fastQC
fastqc -t 24 --nogroup -o out/fastQC out/fastq/*.fq.gz

OUTPUT_NAME=$(basename out/fastQC/*_1_fastqc.html _1_fastqc.html)
multiqc out/fastQC/ -n out/${OUTPUT_NAME}_MultiQC_report.html 
