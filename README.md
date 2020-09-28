# STRT2-NextSeq analysis pipeline

A pipeline for the analysis of STRT2 RNA-sequencing outputs from NextSeq.   

## Install
```
git clone https://github.com/my0916/STRT2.git
```
## Dependencies
For STRT2.sh & STRT2-UPPMAX.sh
- [Picard](https://broadinstitute.github.io/picard/)
- [HISAT2](https://ccb.jhu.edu/software/hisat2/index.shtml)
- [SAMtools](http://samtools.sourceforge.net/)
- [bedtools](https://bedtools.readthedocs.io/en/latest/)
- [Subread](http://subread.sourceforge.net/)

## Requirements
- Illumina BaseCalls files (.bcl). The number of lanes are determined based on the number of directories in the basecalls directory. Here is an example of 4 lanes: 
```
  ├── L001
  ├── L002
  ├── L003
  └── L004
```
- HISAT2 index built with a reference genome, (ribosomal DNA), and ERCC spike-ins 
  - See also [How to build HISAT2 index](#How-to-build-HISAT2-index).
  - The HISAT2 index directory should include the followings:
```
    ├── [basename].1.ht2
    ├── [basename].2.ht2
    ├── [basename].3.ht2
    ├── [basename].4.ht2
    ├── [basename].5.ht2
    ├── [basename].6.ht2
    ├── [basename].7.ht2
    ├── [basename].8.ht2
    ├── [basename].fasta
    └── [basename].dict
```
- Source files (in `src` directory)
  - `barcode.txt` : Barcode sequence with barcode name (1–48). __Please modify if you used different (number of) barcodes.__
  - `ERCC.bed` : 5'-end 50 nt region of ERCC spike-ins ([SRM2374](https://www-s.nist.gov/srmors/view_detail.cfm?srm=2374)) for annotation and quality check.

## Example usage
```
./STRT2.sh -o STRT2LIB -g canFam3 -a ens -b /XXXXX/Data/Intensities/BaseCalls/ \
-i /XXXXX/index/canFam3_reference -c HUDDINGE -r ABCDEFG123
```
For [UPPMAX](https://www.uppmax.uu.se/):
```
sbatch -A snic2017-7-317 -p core -n 8 -t 24:00:00 ./STRT2-UPPMAX.sh -o STRT2LIB -g canFam3 -a ens \
-b /XXXXX/Data/Intensities/BaseCalls/ -i /XXXXX/index/canFam3_reference -c HUDDINGE -r ABCDEFG123 
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
   | `-a, --annotation` | ref | Gene annotation for QC and counting. <br> Choose from `ref`(RefSeq)/`ens`(Ensembl)/`kg`(UCSC KnownGenes), or directly input the Gencode annotation file name (eg. `wgEncodeGencodeBasicV28lift37`) for Gencode. <br>Note that some annotations are unavailable in some cases. Please find the details below.
   | `-c, --center ` | CENTER | The name of the sequencing center that produced the reads.<br>Required for the the Picard IlluminaBasecallsToSam program.|
   | `-r, --run` | RUNBARCODE | The barcode of the run. Prefixed to read names.<br>Required for the the Picard IlluminaBasecallsToSam program.|
   | `-s, --structure` | 8M3S74T6B | Read structure.<br>Required for the the Picard IlluminaBasecallsToSam program.<br>Details are described [here](https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.4.0/picard_illumina_IlluminaBasecallsToSam.php#--READ_STRUCTURE).|
   | `-d, --dta` | | Add `-d, --dta` (downstream-transcriptome-assembly) if you plan to perform [TFE-based analysis](https://github.com/my0916/STRT2/blob/master/TFE-README.md).<br>Please note that this leads to fewer alignments with short-anchors.|
   | `-h, --help`| | Show usage.|
   | `-v, --version`| | Show version.|
   
   - `-a, --annotation` availability as of July 2020:
   
    | | RefSeq (ref) | Ensembl (ens) | KnownGenes (kg) | Gencode |
    | :---: | :---: | :---: | :---: | :---: |
    | hg19 (human) | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
    |  hg38 (human) | :heavy_check_mark: | NA | :heavy_check_mark: | :heavy_check_mark: |
    | mm9 (mouse) | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | NA |
    | mm10 (mouse) | :heavy_check_mark: | NA | :heavy_check_mark: | :heavy_check_mark: |
    | canFam3 (dog) | :heavy_check_mark: | :heavy_check_mark: | NA | NA |
 
## Outputs
Outputs are provided in `out` directory.
Unaligned BAM files generated with Picard IlluminaBasecallsToSam program are found in `tmp/Unaligned_bam`.

- __`OUTPUT`-QC.txt__ <br>
Quality check report for all samples.

   | Column |Value|
   | ------------- | ------------- |
   |`Barcode` | Sample name. `OUTPUT` with numbers|
   |`Qualified_reads` | Primary aligned read count|	
   |`Total_reads`| Read count without redundant (duplicate) reads|
   |`Redundancy` | Qualified reads / Total reads| 
   |`Mapped_reads` | Mapped read count (Total reads without unmapped reads)|
   |`Mapping_rate` | Mapped reads / Total reads|  
   |`Spikein_reads` | Read count mapped to ERCC spike-ins|
   |`Spikein-5end_reads` | Read count mapped to the 5'-end 50 nt region of ERCC spike-ins|
   |`Spikein-5end_rate` | Spikein-5end reads / Spikein reads|
   |`Coding_reads` | Read count aligned within any exon or the 500 bp upstream of coding genes|
   |`Coding-5end_reads` | Read count aligned the 5′-UTR or 500 bp upstream of coding genes| 
   |`Coding-5end_rate` | Coding-5end reads / Coding reads|

- __`OUTPUT`-QC-plots.pdf__ <br>
Quality check report by boxplots.
`Spikein_reads`, `Mapped / Spikein`, `Spikein-5end_rate`, and `Coding-5end_rate` are shown for all samples. Barcode numbers of outlier samples are marked with red characters. 

- __`OUTPUT`\_byGene-counts.txt__ <br>
Read count table output from featureCounts.
http://bioinf.wehi.edu.au/subread-package/SubreadUsersGuide.pdf

- __`OUTPUT`\_byGene-counts.txt.summary__ <br>
Filtering summary from featureCounts.
http://bioinf.wehi.edu.au/subread-package/SubreadUsersGuide.pdf

- __Output_bam__ <br>
Resulting BAM files including unmapped, non-primary aligned, and duplicated (marked) reads.

- __Output_bai__ <br>
Index files (.bai) of the resulting BAM files in the `Output_bam` directory.

- __ExtractIlluminaBarcodes_Metrics__ <br>
Metrics file produced by the Picard ExtractIlluminaBarcodes program. The number of matches/mismatches between the barcode reads and the actual barcodes is shown per lane.
https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.0.0/picard_illumina_ExtractIlluminaBarcodes.php

- __HISAT2_Metrics__ <br>
Alignment summary of samples from each lane produced by the HISAT2 program. 
https://ccb.jhu.edu/software/hisat2/manual.shtml#alignment-summary

- __MarkDuplicates_Metrics__ <br>
Metrics file indicating the numbers of duplicates produced by the Picard MarkDuplicates program.
https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.4.0/picard_sam_markduplicates_MarkDuplicates.php


## fastq-fastQC-UPPMAX.sh
You can generate fastq files for each sample from the output BAM files in the `Output_bam` directory.
FastQC files are also generated for each fastq file.

## How to build HISAT2 index
Here is the case for the dog genome (canFam3).
### 1. Obtain the genome sequences of reference and ERCC spike-ins. 
You may add the ribosomal DNA repetitive unit for human (U13369) and mouse (BK000964).
```
wget http://hgdownload.cse.ucsc.edu/goldenPath/canFam3/bigZips/canFam3.fa.gz
unpigz -c canFam3.fa.gz | ruby -ne '$ok = $_ !~ /^>chrUn_/ if $_ =~ /^>/; puts $_ if $ok' > canFam3_reference.fasta

wget https://www-s.nist.gov/srmors/certificates/documents/SRM2374_putative_T7_products_NoPolyA_v2.FASTA
cat SRM2374_putative_T7_products_NoPolyA_v2.FASTA >> canFam3_reference.fasta
```
### 2. Extract splice sites and exons from a GTF file.
Here Ensembl transcript map (canFam3.transMapEnsemblV4.gtf.gz) was downloaded from the UCSC Table Browser.
```
unpigz -c canFam3.transMapEnsemblV4.gtf.gz | hisat2_extract_splice_sites.py - | grep -v ^chrUn > canFam3.ss
unpigz -c canFam3.transMapEnsemblV4.gtf.gz | hisat2_extract_exons.py - | grep -v ^chrUn | > canFam3.exon
```
You may additionally perform `hisat2_extract_snps_haplotypes_UCSC.py` to extract SNPs and haplotypes from a dbSNP file for human and mouse.

### 3. Build the HISAT2 index.
```
hisat2-build canFam3_reference.fasta --ss canFam3.ss --exon canFam3.exon canFam3_reference
```
This outputs a set of files with suffixes. Here, `canFam3_reference.1.ht2`, `canFam3_reference.2.ht2`, ..., `canFam3_reference.8.ht2` are generated.<br>In this case, `canFam3_reference` is the basename used for `-i, --index`.

### 4. Prepare the sequence dictionary for the reference sequence. 
```
java -jar picard.jar CreateSequenceDictionary R=canFam3_reference.fasta O=canFam3_reference.dict
```
This is required for the Picard MergeBamAlignment program. Note that the original FASTA file (`canFam3_reference.fasta` here) is also required.
