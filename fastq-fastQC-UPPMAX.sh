#!/bin/bash
module load bioinfo-tools
module load samtools/1.9
module load FastQC/0.11.8

mkdir out/Output_bam/fastq
for file in out/Output_bam/*.output.bam; do name=$(basename $file .output.bam); samtools fastq -F 256 -F 1024 $file | pigz -c > out/Output_bam/fastq/$name.fq.gz; done

mkdir out/Output_bam/fastq/fastQC
fastqc -t 22 --nogroup -o out/Output_bam/fastq/fastQC out/Output_bam/fastq/*.fq.gz
