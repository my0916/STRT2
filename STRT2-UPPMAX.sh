#!/bin/bash

PROGNAME="$( basename $0 )"

#Usage
function usage() {
  cat << EOS >&2
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
EOS
  exit 1
}

function version() {
  cat << EOS >&2
STRT2-NextSeq-automated-pipeline ver2019.11.11
EOS
  exit 1
}

#Default parameters
OUTPUT_NAME=output
run_VALUE=runbarcode
center_VALUE=center
READ_STRUCTURE=8M3S74T6B

PARAM=()
for opt in "$@"; do
    case "${opt}" in
    '-o' | '--out' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "${PROGNAME}: option requires an argument -- $( echo $1 | sed 's/^-*//' )" 1>&2
                exit 1
            fi
            OUTNAME=true
            OUTPUT_NAME="$2"
            shift 2
            ;;
    '-g' | '--genome' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
              echo "${PROGNAME}: option requires an argument -- $( echo $1 | sed 's/^-*//' )" 1>&2
              exit 1
            elif [[ "$2" =  "hg19" ]]; then
              GENOME=true
              GENOME_VALUE="hg19"
              shift 2
            elif [[ "$2" =  "hg38" ]]; then
              GENOME=true
              GENOME_VALUE="hg38"
              shift 2
            elif [[ "$2" =  "mm9" ]]; then
              GENOME=true
              GENOME_VALUE="mm9"
              shift 2
            elif [[ "$2" =  "mm10" ]]; then
              GENOME=true
              GENOME_VALUE="mm10"
              shift 2
            elif  [[ "$2" =  "canFam3" ]]; then
              GENOME=true
              GENOME_VALUE="canFam3"
              shift 2
            else
              usage
              exit 1
            fi
            ;;
     '-t' | '--trans' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
              echo "${PROGNAME}: option requires an argument -- $( echo $1 | sed 's/^-*//' )" 1>&2
              exit 1
            elif [[ "$2" =  "ref" ]]; then
              TRAN=true
              TRAN_VALUE="ref"
              shift 2
            elif [[ "$2" =  "known" ]]; then
              TRAN=true
              TRAN_VALUE="known"
              shift 2
            elif [[ "$2" =  "ens" ]]; then
              TRAN=true
              TRAN_VALUE="ens"
              shift 2
            else
              usage
              exit 1
            fi
            ;;
    '-b' | '--basecalls' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "${PROGNAME}: option requires an argument -- $( echo $1 | sed 's/^-*//' )" 1>&2
                exit 1
            fi
            BaseCallsDir=true
            BaseCallsDir_PATH="$2"
            shift 2
            ;;
    '-i' | '--index' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "${PROGNAME}: option requires an argument -- $( echo $1 | sed 's/^-*//' )" 1>&2
                exit 1
            fi
            Index=true
            Index_PATH="$2"
            shift 2
            ;;
    '-c' | '--center' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "${PROGNAME}: option requires an argument -- $( echo $1 | sed 's/^-*//' )" 1>&2
                exit 1
            fi
            center=true
            center_VALUE="$2"
            shift 2
            ;;
    '-r' | '--run' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "${PROGNAME}: option requires an argument -- $( echo $1 | sed 's/^-*//' )" 1>&2
                exit 1
            fi
            run=true
            run_VALUE="$2"
            shift 2
            ;;
    '-s' | '--structure' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "${PROGNAME}: option requires an argument -- $( echo $1 | sed 's/^-*//' )" 1>&2
                exit 1
            fi
            structure=true
            READ_STRUCTURE="$2"
            shift 2
            ;;
    '-h' | '--help' )
            usage
            ;;
    '-v' | '--version' )
            version
            ;;
    '--' | '-' )
            shift
            PARAM+=( "$@" )
            break
            ;;
    -* )
            echo "${PROGNAME}: illegal option -- '$( echo $1 | sed 's/^-*//' )'" 1>&2
            exit 1
            ;;
    esac
done

if [[ -n "${PARAM[@]}" ]]; then
    usage
fi

[ "${GENOME}" != "true" ] && usage
[ "${BaseCallsDir}" != "true" ] && usage
[ "${Index}" != "true" ] && usage
[ "${TRAN}" != "true" ] && TRAN_VALUE=ref

#Loading required tools
module load bioinfo-tools
module load picard/2.20.4
module load HISAT2/2.1.0
module load samtools/1.9
module load BEDTools/2.27.1
module load subread/1.5.2
module load ruby/2.6.2

#Preparation for annotation and QC
if [[ ${TRAN_VALUE} =  "ens" ]]; then
  echo "downloading the ENSEMBL transcriptome data..."
  curl -o src/ensGene.txt.gz http://hgdownload.cse.ucsc.edu/goldenPath/${GENOME_VALUE}/database/ensGene.txt.gz
  curl -o src/ensemblToGeneName.txt.gz http://hgdownload.cse.ucsc.edu/goldenPath/${GENOME_VALUE}/database/ensemblToGeneName.txt.gz
  gunzip src/ensGene.txt.gz
  gunzip src/ensemblToGeneName.txt.gz
  join -1 1 -2 2 -t $'\t' <(sort -k 1,1 src/ensemblToGeneName.txt) <(sort -k 2,2 src/ensGene.txt) > src/common.txt
  join -1 1 -2 2 -t $'\t' -v 2 <(sort -k 1,1 src/ensemblToGeneName.txt) <(sort -k 2,2 src/ensGene.txt) | awk 'BEGIN{OFS="\t"}{print $2,$13,$1,$1=$2="",$0}' | cut -f 1-3,7- > src/no-genename.txt
  cat src/common.txt src/no-genename.txt > src/ens-genes.txt
  rm src/common.txt && rm src/no-genename.txt
  ruby ruby/ENSEMBL-extract.rb
  rm src/ens-genes.txt
  shift 2
elif [[ ${TRAN_VALUE} =  "known" ]]; then
  echo "downloading the UCSC known genes transcriptome data..."
  curl -o src/knownGene.txt.gz http://hgdownload.cse.ucsc.edu/goldenPath/${GENOME_VALUE}/database/knownGene.txt.gz
  curl -o src/kgXref.txt.gz http://hgdownload.cse.ucsc.edu/goldenPath/${GENOME_VALUE}/database/kgXref.txt.gz
  gunzip src/knownGene.txt.gz
  gunzip src/kgXref.txt.gz
  join  -1 1 -2 1 -t $'\t' <(sort -k 1,1 src/kgXref.txt | cut -f 1-5) <(sort -k 1,1 src/knownGene.txt) > src/knowngene-names.txt
  rm src/knownGene.txt && rm src/kgXref.txt
  ruby ruby/KnownGenes-extract.rb
  rm src/knowngene-names.txt
  shift 2
elif [[ ${TRAN_VALUE} =  "ref" ]]; then
  echo "downloading the NCBI RefSeq transcriptome data..."
  curl -o src/refGene.txt.gz http://hgdownload.cse.ucsc.edu/goldenPath/${GENOME_VALUE}/database/refGene.txt.gz
  gunzip src/refGene.txt.gz
  ruby ruby/RefSeq-extract.rb
  shift 2
else
  usage
  exit 1
fi

echo "downloading the chromosome size data..."
curl -o src/${GENOME_VALUE}.chrom.sizes http://hgdownload.soe.ucsc.edu/goldenPath/${GENOME_VALUE}/bigZips/${GENOME_VALUE}.chrom.sizes
cat src/${GENOME_VALUE}.chrom.sizes | awk '{print $1"\t"1"\t"$2}' | sortBed -i > src/chrom.size.bed 
cat src/proxup.bed | grep -v _alt  | grep -v _hap | grep -v _fix | grep -v _random | grep -v chrUn | sortBed -i stdin | intersectBed -a stdin -b src/chrom.size.bed > src/proxup_trimmed.bed

cat src/5utr.bed src/proxup_trimmed.bed | grep -v _alt | grep -v _hap | grep -v _fix | grep -v _random | grep -v chrUn | sortBed -i stdin | mergeBed -s -o distinct,distinct,distinct -c 4,5,6 -i - | grep -v , > src/coding_5end.bed

cat src/exon.bed src/proxup_trimmed.bed | grep -v _alt | grep -v _hap | grep -v _fix | grep -v _random | grep -v chrUn | sortBed -i stdin | mergeBed -s -o distinct,distinct,distinct -c 4,5,6 -i - > src/coding.bed

cat src/ERCC.bed src/coding_5end.bed | awk '{print $4 "\t" $1 "\t" $2+1 "\t" $3 "\t" $6}' > src/5end-regions.saf

rm src/${GENOME_VALUE}.chrom.sizes
rm src/5utr.bed 
rm src/exon.bed
rm src/proxup.bed
rm src/proxup_trimmed.bed

#Temporary and output directory
mkdir tmp
mkdir out

#Preparation for barcodes
for i in {1..48}
do
echo -e ${OUTPUT_NAME}_${i}_Lane1.bam"\t"${OUTPUT_NAME}_${i}_Lane1"\t"${OUTPUT_NAME}_${i}_Lane1 >> tmp/out
done
paste tmp/out <(awk 'NR>1{print $1}' src/barcode.txt) | cut -f 1-4 > tmp/out2 && rm tmp/out
echo -e ${OUTPUT_NAME}_non-indexed_Lane1.bam"\t"${OUTPUT_NAME}_non-indexed_Lane1"\t" ${OUTPUT_NAME}_non-indexed_Lane1"\t"N >> tmp/out2
echo -e OUTPUT"\t"SAMPLE_ALIAS"\t"LIBRARY_NAME"\t"BARCODE_1  | cat - tmp/out2 > library.param.lane1 && rm tmp/out2

sed -e "s/Lane1/Lane2/g" library.param.lane1 > library.param.lane2
sed -e "s/Lane1/Lane3/g" library.param.lane1 > library.param.lane3
sed -e "s/Lane1/Lane4/g" library.param.lane1 > library.param.lane4

#Convert BCL files to BAM files
for i in {1..4}
do
java -Xmx16g -jar $PICARD_HOME/picard.jar ExtractIlluminaBarcodes \
BASECALLS_DIR=${BaseCallsDir_PATH}/ \
LANE=${i} \
READ_STRUCTURE=${READ_STRUCTURE} \
BARCODE_FILE=src/barcode.txt  \
METRICS_FILE=metrics_output_lane${i}.txt ;
java -Xmx16g -jar $PICARD_HOME/picard.jar IlluminaBasecallsToSam \
BASECALLS_DIR=${BaseCallsDir_PATH}/ \
LANE=${i} \
READ_STRUCTURE=${READ_STRUCTURE} \
RUN_BARCODE=${run_VALUE} \
IGNORE_UNEXPECTED_BARCODES=true \
LIBRARY_PARAMS=library.param.lane${i} \
SEQUENCING_CENTER=${center_VALUE} \
INCLUDE_NON_PF_READS=false
done

rm library.param.lane*
mkdir out/ExtractIlluminaBarcodes && mv metrics_output_lane*.txt out/ExtractIlluminaBarcodes

#Mapping by HISAT2 and merging with the original unaligned BAM files to generate UMI-annotated BAM files
mkdir tmp/UMI
mkdir out/HISAT2

for file in *.bam
do
name=$(basename $file .bam)
echo $name >> out/HISAT2/mapping-summary.txt 
java -Xmx16g -jar $PICARD_HOME/picard.jar SortSam \
      I=$file \
      O=tmp/.unmapped.sorted.bam \
     SORT_ORDER=queryname;
java -Xmx16g -jar $PICARD_HOME/picard.jar SamToFastq \
I=tmp/.unmapped.sorted.bam \
F=/dev/stdout \
  | hisat2 -p 8 --dta -x ${Index_PATH} \
    -U /dev/stdin -S /dev/stdout \
    2>> out/HISAT2/mapping-summary.txt  \
    |java -Xmx16g -jar $PICARD_HOME/picard.jar SortSam \
      I=/dev/stdin \
      O=tmp/.mapped.sorted.sam \
      SORT_ORDER=queryname;
      java -Xmx16g -jar $PICARD_HOME/picard.jar MergeBamAlignment \
      ATTRIBUTES_TO_RETAIN=XS \
      UNMAPPED=tmp/.unmapped.sorted.bam  \
      ALIGNED=tmp/.mapped.sorted.sam \
      O=tmp/UMI/$name.umi.bam \
      R=${Index_PATH}.fasta
done

rm tmp/.unmapped.sorted.bam
rm tmp/.mapped.sorted.sam
mkdir tmp/merged
mkdir unmapped_bam
mv *.bam unmapped_bam

#Merging 4 lanes
for i in {1..48}
do
java -Xmx16g -jar $PICARD_HOME/picard.jar MergeSamFiles \
I=tmp/UMI/${OUTPUT_NAME}_${i}_Lane1.umi.bam \
I=tmp/UMI/${OUTPUT_NAME}_${i}_Lane2.umi.bam \
I=tmp/UMI/${OUTPUT_NAME}_${i}_Lane3.umi.bam \
I=tmp/UMI/${OUTPUT_NAME}_${i}_Lane4.umi.bam \
O=/dev/stdout |
java -Xmx16g -jar $PICARD_HOME/picard.jar AddOrReplaceReadGroups \
I=/dev/stdin \
O=tmp/merged/${OUTPUT_NAME}_${i}.merged.bam \
RGLB=${OUTPUT_NAME}_${i} RGPL=NextSeq RGPU=${i} RGSM=${i}
done

rm -rf tmp/UMI

#Mark potential PCR duplicates 
mkdir out/MarkDuplicates
for i in {1..48}
do
java -Xmx16g -jar $PICARD_HOME/picard.jar MarkDuplicates \
INPUT=tmp/merged/${OUTPUT_NAME}_${i}.merged.bam \
OUTPUT=out/${OUTPUT_NAME}_${i}.output.bam \
METRICS_FILE=out/MarkDuplicates/${OUTPUT_NAME}_${i}.metrics.txt \
BARCODE_TAG=RX
done

rm -rf tmp/merged

#Quality check
cd out

echo -e barcode"\t"Qualified reads"\t"Total reads"\t"Redundancy"\t"Mapped reads"\t"Mapping rate\
"\t"Spikein reads"\t"Spikein-5end reads"\t"Spikein-5end rate"\t"Coding reads"\t"Coding-5end reads"\t"Coding-5end rate > ${OUTPUT_NAME}-summary.txt

for file in *.output.bam
do
name=$(basename $file .output.bam)
samtools index $file
QR=$(samtools view -F 256 $file | wc -l)
Total=$(samtools view -F 256 -F 1024 $file | wc -l)
Redundancy=$(echo "scale=2;$QR/$Total" | bc)
Map=$(samtools view -F 256 -F 1024 -F 4 $file | wc -l)
Rate=$(echo "scale=1;$Map*100/$Total" | bc)
Spike=$(samtools view -F 256 -F 1024 -F 4 $file |grep -e ERCC -e NIST| wc -l)
spikein_5end_reads=$(samtools view -u -F 256 -F 1024 -F 4 $file | intersectBed -abam stdin -wa -bed -b ../src/ERCC.bed | cut -f 4 | sort -u | wc -l)
spikein_5end_rate=$(echo "scale=1;$spikein_5end_reads*100/$Spike" | bc)
coding_reads=$(samtools view -u -F 256 -F 1024 -F 4 $file | intersectBed -abam stdin -wa -bed -b ../src/coding.bed | cut -f 4 | sort -u | wc -l)
coding_5end_reads=$(samtools view -u -F 256 -F 1024 -F 4 $file | intersectBed -abam stdin -wa -bed -b ../src/coding_5end.bed | cut -f 4 | sort -u | wc -l)
coding_5end_rate=$(echo "scale=1;$coding_5end_reads*100/$coding_reads" | bc)
echo -e $name"\t"$QR"\t"$Total"\t"$Redundancy"\t"$Map"\t"$Rate"\t"$Spike"\t"$spikein_5end_reads"\t"$spikein_5end_rate"\t"$coding_reads"\t"$coding_5end_reads"\t"$coding_5end_rate >> ${OUTPUT_NAME}-summary.txt 
done

#Counting by featureCounts
featureCounts -T 8 -s 1 --largestOverlap --ignoreDup --primary -a ../src/5end-regions.saf -F SAF -o ${OUTPUT_NAME}_byGene_raw-counts.txt *.bam

mkdir index && mv *.bam.bai index
mkdir bam && mv *.bam bam
