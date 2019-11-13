# STRT2-NextSeq analysis pipeline

A pipeline for the analysis of STRT2 sequencing outputs from NextSeq.   

## Install
```
git clone https://github.com/my0916/STRT2.git
```
## Dependencies
For STRT2.sh
- [Picard](https://broadinstitute.github.io/picard/)
- [HISAT2](https://ccb.jhu.edu/software/hisat2/index.shtml)
- [SAMtools](http://samtools.sourceforge.net/)
- [bedtools](https://bedtools.readthedocs.io/en/latest/)
- [Subread](http://subread.sourceforge.net/)

## Requirements
- Illumina BaseCalls files (.bcl)
- HISAT2 index built with a reference genome, (ribosomal DNA), and [ERCC spike-ins](https://www-s.nist.gov/srmors/certificates/documents/SRM2374_putative_T7_products_NoPolyA_v2.FASTA)
  - See also [How to build HISAT2 index](#How-to-build-HISAT2-index).
- Source files (in `src` directory)
  - `barcode.txt` : Barcode sequence with barcode name (1-48).
  - `ERCC.bed` : 5'-end 50 nt region of ERCC spike-ins for annotation and quality check.

## Example usage
```
./STRT2.sh -o STRT2LIB -g canFam3 -a ens -b /XXXXX/Data/Intensities/BaseCalls/ \
-i /XXXXX/index/canFam3_ensemblV4_ercc -c HUDDINGE -r ABCDEFG123
```
For UPPMAX:
```
sbatch -A snic2017-7-317 -p core -n 8 -t 24:00:00 ./STRT2-UPPMAX.sh -o STRT2LIB -g canFam3 -a ens \
-b /XXXXX/Data/Intensities/BaseCalls/ -i /XXXXX/index/canFam3_ensemblV4_ercc -c HUDDINGE -r ABCDEFG123 
```

## Parameters
- __Mandatory__

   | Name | Description |
   | :--- | :--- |
   | `-g, --genome` | Reference genome. Choose from `hg19`/`hg38`/`mm9`/`mm10`/`canFam3`. |
   | `-b, --basecalls` | /PATH/to/the Illumina basecalls directory.|
   | `-i, --index` | /PATH/to/the directory and basename of the HISAT2 index for the reference genome. |

- __Optional__

   | Name&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|Default value|Description|
   | :--- | :--- | :--- |
   | `-o, --out` | OUTPUT | Output file name.|
   | `-a, --annotation` | ref | Gene annotation for QC and counting. <br> Choose from `ref`(RefSeq)/`ens`(Ensembl)/`kg`(UCSC KnownGenes). <br>Note that Ensembl and UCSC KnownGenes are not available in some cases. Please find the details below.
   | `-c, --center ` | CENTER | The name of the sequencing center that produced the reads.<br>Required for the the Picard IlluminaBasecallsToSam program.|
   | `-r, --run` | RUNBARCODE | The barcode of the run. Prefixed to read names.<br>Required for the the Picard IlluminaBasecallsToSam program.|
   | `-s, --structure` | 8M3S74T6B | Read structure.<br>Required for the the Picard IlluminaBasecallsToSam program.<br>Detais are described [here](https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.4.0/picard_illumina_IlluminaBasecallsToSam.php#--READ_STRUCTURE).|
   | `-h, --help`| | Show usage.|
   | `-v, --version`| | Show version.|
   
   - `-a, --annotation` availability:
   
    | | RefSeq (ref) | Ensembl (ens) | KnownGenes (kg) |
    | :---: | :---: | :---: | :---: |
    | hg19 (human) | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
    |  hg38 (human) | :heavy_check_mark: | NA | :heavy_check_mark: |
    | mm9 (mouse) | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
    | mm10 (mouse) | :heavy_check_mark: | NA | :heavy_check_mark: |
    | canFam3 (dog) | :heavy_check_mark: | :heavy_check_mark: | NA |
 
## Outputs
Outputs are provided in `out` directory.
Unaligned BAM files generated with Picard IlluminaBasecallsToSam program are found in `tmp/Unaligned_bam`.

- __`OUTPUT`-QC.txt__ <br>
Quality check report for all samples.

   | Column |Value|
   | ------------- | ------------- |
   |`Barcode` | Sample name. `OUTPUT` with numbers (1-48)|
   |`Qualified reads` | Primary aligned read count|	
   |`Total reads`| Read count without redundant (duplicate) reads|
   |`Redundancy` | Qualified reads / Total reads| 
   |`Mapped reads` | Mapped read count (Total reads without unmapped reads)|
   |`Mapping rate` | Mapped reads / Total reads|  
   |`Spikein reads` | Read count mapped to ERCC spike-ins|
   |`Spikein-5end reads` | Read count mapped to the 5'-end 50 nt region of ERCC spike-ins|
   |`Spikein-5end rate` | Spikein-5end reads / Spikein reads|
   |`Coding reads` | Read count aligned within any exon or the 500 bp upstream of coding genes|
   |`Coding-5end reads` | Read count aligned the 5′-UTR or 500 bp upstream of coding genes| 
   |`Coding-5end rate` | Coding-5end reads / Coding reads|

- __`OUTPUT`\_byGene-counts.txt__ <br>
Read count table output from featureCounts. Details are described here: http://subread.sourceforge.net/

- __`OUTPUT`\_byGene-counts.txt.summary__ <br>
Filtering summary from featureCounts. Details are described here: http://subread.sourceforge.net/

- __Output_bam__ <br>
Resulting BAM files including unmapped, non-primary aligned, and duplicated (marked) reads.

- __Output_bai__ <br>
Index files (.bai) of the resulting BAM files in the `Output_bam` directory.

- __ExtractIlluminaBarcodes_Metrics__ <br>
Metrics file produced by the Picard ExtractIlluminaBarcodes program.
https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.0.0/picard_illumina_ExtractIlluminaBarcodes.php

- __HISAT2_Metrics__ <br>
Alignment summary of samples from each lane produced by the HISAT2 program. 
https://ccb.jhu.edu/software/hisat2/manual.shtml#alignment-summary

- __MarkDuplicates_Metrics__ <br>
Metrics file indicating the numbers of duplicates produced by the Picard MarkDuplicates program.
https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.4.0/picard_sam_markduplicates_MarkDuplicates.php


## How to build HISAT2 index
Here is the case for the dog genome (canFam3).
### 1. Obtain the genome sequences of reference and ERCC spike-ins. 
You may add the ribosomal DNA sequence for human (U13369) and mouse (BK000964).
```
wget http://hgdownload.cse.ucsc.edu/goldenPath/canFam3/bigZips/canFam3.fa.gz
unpigz -c canFam3.fa.gz | ruby -ne '$ok = $_ !~ /^>chrUn_/ if $_ =~ /^>/; puts $_ if $ok' > canFam3_ercc.fa

wget https://www-s.nist.gov/srmors/certificates/documents/SRM2374_putative_T7_products_NoPolyA_v2.FASTA
cat SRM2374_putative_T7_products_NoPolyA_v2.FASTA >> canFam3_ercc.fa
```
### 2. Extract splice sites and exons from a GTF file.
Here Ensembl transcript map (canFam3.transMapEnsemblV4.gtf.gz) was downloaded from the UCSC Table Browser.
```
unpigz -c canFam3.transMapEnsemblV4.gtf.gz | hisat2_extract_splice_sites.py - | grep -v ^chrUn > canFam3.ss
unpigz -c canFam3.transMapEnsemblV4.gtf.gz | hisat2_extract_exons.py - | grep -v ^chrUn | > canFam3.exon
```
### 3. Build the HISAT2 index.
```
hisat2-build canFam3_ercc.fa --ss canFam3.ss --exon canFam3.exon canFam3_ensemblV4_ercc
```
In this case, `canFam3_ensemblV4_ercc` is the basename used for `-i, --index`.
