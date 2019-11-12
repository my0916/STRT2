# STRT2-NextSeq analysis pipeline

A pipeline for the analysis of STRT2 sequencing outputs from NextSeq.   

## Install
```
git clone https://github.com/my0916/STRT2.git
```

## Requirements
- Illumina BaseCalls files (.bcl)
- HISAT2 index built with a reference genome/transcriptome, ribosomal DNA, and ERCC spike-ins (https://www-s.nist.gov/srmors/certificates/documents/SRM2374_putative_T7_products_NoPolyA_v2.FASTA)
- Source files (src)
  - `barcode.txt` : Barcode sequence with barcode name (1-48).
  - `ERCC.bed` : 5'-end 50 nt region of ERCC spike-ins for annotation and quality check.

## Usage
```
STRT2-UPPMAX.sh [-o String] [-g genome (required)] [-t transcriptome] [-b Path (required)] [-i Path (required)] [-c String] [-r String] [-s String]

Options:
  -o, --out               Output file name. (default: output)
  -g, --genome            Genome (hg19/hg38/mm9/mm10/canFam3) for annotation and QC. Required!
  -t, --transcriptome     Transcriptome (ref{RefSeq}/ens{ENSEMBL}/known{UCSC known genes}) for annotation and QC. Default : ref. NOTE: no ENSEMBL for hg38&mm10, no known genes for canFam3.  
  -b, --basecalls         /PATH/to/the Illumina basecalls directory. Required!
  -i, --index             /PATH/to/the directory and basename of the HISAT2 index for the reference genome. Required! 
  -c, --center            The name of the sequencing center that produced the reads. (default: center)
  -r, --run               The barcode of the run. Prefixed to read names. (default: runbarcode)
  -s, --structure         Read structure (default: 8M3S74T6B)
  -h, --help              Show usage.
  -v, --version           Show version.
```

## Example
```
sbatch -A snic2017-7-317 -p core -n 8 -t 24:00:00 ./STRT2-UPPMAX.sh -o 191111test -g canFam3 -t ens
-bc /XXXXX/Data/Intensities/BaseCalls/ -c KI -r ABCDEFGHIJ -i /XXXXX/index/canFam3_ensemblV4_ercc
```

## Outputs
Outputs are found in the 'out' directory.
Unaligned BAM files generated with Picard IlluminaBasecallsToSam program are in the 'Unaligned_bam' directory.

### 1. `OUTPUT`-QC-summary.txt
Quality check report for all samples.
- `Barcode` : Sample name. {OUTPUT} with numbers (1-48).
- `Qualified reads`: Primary aligned read count.	
- `Total reads` : Read count without redundant (duplicate) reads.
- `Redundancy` : Qualified reads / Total reads. 
- `Mapped reads` : Mapped read count (Total reads without unmapped reads). 
- `Mapping rate` : Mapped reads / Total reads. 
- `Spikein reads` : Read count mapped to ERCC spike-ins.
- `Spikein-5end reads` : Read count mapped to the 5'-end 50 nt region of ERCC spike-ins.
- `Spikein-5end rate` : Spikein-5end reads / Spikein reads.
- `Coding reads` : Read count aligned within any exon or the 500 bp upstream of coding genes.
- `Coding-5end reads` : Read count aligned the 5′-UTR or 500 bp upstream of coding genes. 
- `Coding-5end rate` : Coding-5end reads / Coding reads.

### 2. `OUTPUT`_byGene-raw-counts.txt
Read count table output from featureCounts. Details are described here: http://subread.sourceforge.net/

### 3. `OUTPUT`_byGene-raw-counts.txt.summary
Filtering summary from featureCounts. Details are described here: http://subread.sourceforge.net/

### 4. Output-bam
Resulting BAM files including unmapped, non-primary aligned, and duplicated (marked) reads.

### 5. Index
Index files of the resulting BAM files in the 'bam' directory.

### 6. ExtractIlluminaBarcodes
Metrics file produced by the Picard ExtractIlluminaBarcodes program.
https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.0.0/picard_illumina_ExtractIlluminaBarcodes.php

### 7. HISAT2
Mapping summary of samples from each lane produced by the HISAT2 program. 
https://ccb.jhu.edu/software/hisat2/manual.shtml

### 8. MarkDuplicates
Metrics file indicating the numbers of duplicates produced by the Picard MarkDuplicates program.
https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.4.0/picard_sam_markduplicates_MarkDuplicates.php
