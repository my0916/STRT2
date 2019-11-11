# STRT2-NextSeq analysis pipeline

A pipeline for the analysis of STRT2 sequencing outputs from NextSeq.   

## Install
```
git clone https://github.com/my0916/STRT2.git
```

## Usage
```
STRT2-UPPMAX.sh [-o String] [-g genome (required)] [-t transcriptome] [-b Path (required)] [-i Path (required)] [-c String] [-r String] [-s String]

Options:
  -o, --out               Output file name. (default: output)
  -g, --genome            Genome (hg19/hg38/mm9/mm10/canFam3) for annotation and QC. Required!
  -t, --transcriptome     Transcriptome (ref{RefSeq}/ens{ENSEMBL}/known{UCSC known genes}) for annotation and QC. Default : ref. NOTE: no ENSEMBL for hg38&mm10, no known genes for canFam3.  
  -b, --basecalls         /PATH/to/The Illumina basecalls directory. Required!
  -i, --index             /PATH/to/The directory and basename of the HISAT2 index for the reference genome. Required! 
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
### - {OUTPUT}-summary.txt
A quality check report for all samples.
- ```Barcode``` : Sample name. ${OUTPUT_NAME} with numbers (1-48).
- ```Qualified reads``` : Primary aligned read count.	
- ```Total reads``` : Read count without redundant (duplicate) reads.
- ```Redundancy``` : Qualified reads / Total reads. 
- ```Mapped reads``` : Mapped read count (Total reads without unmapped reads). 
- ```Mapping rate``` : Mapped reads / Total reads. 
- ```Spikein reads``` : Read count mapped to ERCC spike-ins.
- ```Spikein-5end reads``` : Read count mapped to the 5'-end 50 nt region of ERCC spike-ins.
- ```Spikein-5end rate``` : Spikein-5end reads / Spikein reads.
- ```Coding reads``` : Read count aligned within any exon or the 500 bp upstream of coding genes.
- ```Coding-5end reads``` : Read count aligned the 5′-UTR or 500 bp upstream of coding genes. 
- ```Coding-5end rate``` : Coding-5end reads / Coding reads.

### - {OUTPUT}_byGene-raw-counts.txt
Output from featureCounts http://subread.sourceforge.net/
