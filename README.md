# STRT2
Usage: ${PROGNAME} [-o String] [-g genome (required)] [-t transcriptome] [-b Path (required)] [-i Path (required)] [-c String] [-r String] [-s String]

Options:
  -o, --out               Output file name. (default: output)
  -g, --genome            Genome (hg19/hg38/mm9/mm10/canFam3) for annotation and QC. Required!
  -t, --trans             Transcriptome (ref{RefSeq}/ens{ENSEMBL}/known{UCSC known genes}) for annotation and QC. Default : ref. NOTE: no ENSEMBL for hg38&mm10, no known genes for canFam3.  
  -b, --basecalls         /PATH/to/The Illumina basecalls directory. Required!
  -i, --index             /PATH/to/The directory and basename of the HISAT2 index for the reference genome. Required! 
  -c, --center            The name of the sequencing center that produced the reads. (default: center)
  -r, --run               The barcode of the run. Prefixed to read names. (default: runbarcode)
  -s, --structure         Read structure (default: 8M3S74T6B)
  -h, --help              Show usage.
  -v, --version           Show version.
