#!/bin/bash
PROGNAME="$( basename $0 )"

#Usage
function usage() {
  cat << EOS >&2
Usage: ${PROGNAME} [-o <output>] 
Options:
  -o, --out               Output file name. (default: OUTPUT)
  -c, --coverage          Minimum read coverage allowed for the predicted transcripts. (default: 5)
  -l, --length            Minimum length allowed for the predicted transcripts. (default: 74)
  -h, --help              Show usage.
  -v, --version           Show version.
EOS
  exit 1
}

function version() {
  cat << EOS >&2
STRT2-NextSeq-automated-pipeline_TFE-based ver2019.12.19
EOS
  exit 1
}

#Default parameters
OUTPUT_NAME=OUTPUT
cover_VALUE=5
len_VALUE=74


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
    '-c' | '--coverage' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "${PROGNAME}: option requires an argument -- $( echo $1 | sed 's/^-*//' )" 1>&2
                exit 1
            fi
            coverage=true
            cover_VALUE="$2"
            shift 2
            ;;
    '-l' | '--length' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "${PROGNAME}: option requires an argument -- $( echo $1 | sed 's/^-*//' )" 1>&2
                exit 1
            fi
            length=true
            len_VALUE="$2"
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

module load bioinfo-tools
module load samtools/1.9
module load StringTie/1.3.3
module load BEDTools/2.27.1
module load subread/1.5.2
module load ruby/2.6.2

mkdir byTFE_tmp
mkdir byTFE_out

#Merge all BAMs, remove duplicated, non-primary, unmapped reads, and sort
samtools merge -@ 8 - forTFE/*.bam | samtools view -@ 8 -b -F 256 -F 1024 -F 4 - | samtools sort -@ 8 -o byTFE_tmp/${OUTPUT_NAME}_merged.bam

#Assembly with Stringtie 
stringtie byTFE_tmp/${OUTPUT_NAME}_merged.bam -o byTFE_tmp/${OUTPUT_NAME}_stringtie.gtf -p 8 -m ${len_VALUE} --fr -l ${OUTPUT_NAME} -c ${cover_VALUE}

#Extract 1st-exon
cat byTFE_tmp/${OUTPUT_NAME}_stringtie.gtf | awk '{if($7=="+"||$7=="."){print $0}}'| grep 'exon_number "1"' | awk 'OFS =  "\t" {print $1,$4-1,$5,$12,"0",$7}' | sed -e 's/"//g'| sed -e 's/;//g' > byTFE_tmp/${OUTPUT_NAME}_firstExons-fwd.bed 
cat byTFE_tmp/${OUTPUT_NAME}_stringtie.gtf | awk 'BEGIN{OFS="\t"}{if($7=="-" && $3=="exon"){print $1,$4-1,$5,$12,"0",$7}}' | sed -e 's/"//g'| sed -e 's/;//g' | sort -k 4,4 -k 1,1 -k 2,2n | bedtools groupby -i stdin -g 4  -c 1,2,3,4,5,6 -o last | awk 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6,$7}' > byTFE_tmp/${OUTPUT_NAME}_firstExons-rev.bed

cat byTFE_tmp/${OUTPUT_NAME}_firstExons-fwd.bed  byTFE_tmp/${OUTPUT_NAME}_firstExons-rev.bed | sortBed -i stdin > byTFE_tmp/${OUTPUT_NAME}_firstExons.bed
rm byTFE_tmp/${OUTPUT_NAME}_firstExons-fwd.bed 
rm byTFE_tmp/${OUTPUT_NAME}_firstExons-rev.bed

#Spike-ins were not annotated as TFE with numbers
sort -k 1,1 -k 2,2n byTFE_tmp/${OUTPUT_NAME}_firstExons.bed |awk '{if($6=="+"){print $0}}' | grep -e ERCC -e NIST |mergeBed -s -c 6 -o distinct | bedtools groupby -i stdin -g 1  -c 1,2,3,4 -o first| awk 'BEGIN{OFS="\t"}{print $2,$3,$4,"RNA_SPIKE_"$2,0,$5}' > byTFE_tmp/${OUTPUT_NAME}_spike-firstExons.bed 
sort -k 1,1 -k 2,2n byTFE_tmp/${OUTPUT_NAME}_firstExons.bed | mergeBed -s -c 6 -o distinct | grep -v ERCC| grep -v NIST | awk 'BEGIN{OFS="\t"}{print $1,$2,$3,"TFE"NR,0,$4}' > byTFE_tmp/${OUTPUT_NAME}_nonspike-firstExons.bed 
cat byTFE_tmp/${OUTPUT_NAME}_spike-firstExons.bed  byTFE_tmp/${OUTPUT_NAME}_nonspike-firstExons.bed > byTFE_out/${OUTPUT_NAME}_TFE-regions.bed

#Counting
awk '{print $4 "\t" $1 "\t" $2+1 "\t" $3 "\t" $6}' byTFE_out/${OUTPUT_NAME}_TFE-regions.bed > byTFE_out/${OUTPUT_NAME}_TFE-regions.saf
featureCounts -T 8 -s 1 --largestOverlap --ignoreDup --primary -a byTFE_out/${OUTPUT_NAME}_TFE-regions.saf -F SAF -o byTFE_out/${OUTPUT_NAME}_byTFE-counts.txt forTFE/*.bam

#Peaks
cd forTFE
mkdir bedGraph
for file in *.output.bam
do
name=$(basename $file .output.bam)
samtools index $file
Spike=$(samtools view -F 256 -F 1024 -F 4 $file |grep -e ERCC -e NIST| wc -l)
samtools view -b -F 256 -F 1024 -F 4 $file | bamToBed -i stdin\
| gawk 'BEGIN{ FS="\t"; OFS=" " }{if($6=="+"){print $1,$2,$2+1,".",0,"+"}else{print $1,$3-1,$3,".",0,"-"}}'\
| sort -k 1,1 -k 2,2n\
| uniq -c\
| gawk 'BEGIN{ FS=" "; OFS="\t" }{print $2,$3,$4,$5,$1/'$Spike',$7}'\
| pigz -c > bedGraph/$name.bedGraph.gz
done
mkdir bai && mv *.bam.bai bai
gunzip -c bedGraph/*.bedGraph.gz | sort -k 1,1 -k 2,2n | mergeBed -s -c 4,5,6 -o distinct,sum,distinct -d -1  > ../byTFE_tmp/${OUTPUT_NAME}_fivePrimes.bed
cd ../
intersectBed -wa -wb -s -a byTFE_out/${OUTPUT_NAME}_TFE-regions.bed -b byTFE_tmp/${OUTPUT_NAME}_fivePrimes.bed \
| cut -f 4,7,8,9,11,12 \
| gawk 'BEGIN{ FS="\t"; OFS="\t" }{p=$6=="+"?$3:-$4;print $2,$3,$4,$1,$5,$6,p,$1}' \
| sort -k 8,8 -k 5,5gr -k 7,7g \
| uniq -f 7 \
| cut -f 1-6 \
| sort -k 1,1 -k 2,2n > byTFE_out/${OUTPUT_NAME}_peaks.bed

#Annotation of peaks
mkdir src/anno
if test -f src/ensGene.txt && test ! -f src/knownGene.txt && test ! -f src/refGene.txt; then
  echo "Annotation with Ensembl"
  ruby ruby/ensGene_annotation.rb
  shift 2
elif test ! -f src/ensGene.txt && test -f src/knownGene.txt && test ! -f src/refGene.txt; then
  echo "Annotation with UCSC KnownGenes"
  ruby ruby/knownGene_annotation.rb
  shift 2
elif test ! -f src/ensGene.txt && test ! -f src/knownGene.txt && test -f src/refGene.txt; then
  echo "Annotation with NCBI RefSeq"
  ruby ruby/refGene_annotation.rb
  shift 2
else
  echo "Something is wrong with the annotation data file"
  exit 1
fi

intersectBed -a src/anno/Coding-up.bed -b src/chrom.size.bed > src/anno/Coding-up_trimmed.bed
intersectBed -a src/anno/NC-up.bed -b src/chrom.size.bed > src/anno/NC-up_trimmed.bed

intersectBed -s -wa -wb -a byTFE_out/${OUTPUT_NAME}_peaks.bed -b src/anno/Coding-5UTR.bed | awk -F "\t" '{print($4,$10)}' \
|awk -F "|" '{if(a[$1])a[$1]=a[$1]";"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -F " " '{print $1"\t"$2","$3}' \
|awk -F "\t" '{if(a[$1])a[$1]=a[$1]":"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -v 'OFS=\t' '{print $1,$2,"Coding_5UTR"}' | sort -k 1,1 > src/anno/peaks_class1.txt


intersectBed -s -wa -wb -a byTFE_out/${OUTPUT_NAME}_peaks.bed -b src/anno/Coding-5UTR.bed -v > src/anno/peaks_nonClass1.bed
intersectBed -s -wa -wb -a src/anno/peaks_nonClass1.bed -b src/anno/Coding-up_trimmed.bed | awk -F "\t" '{print($4,$10)}' \
|awk -F "|" '{if(a[$1])a[$1]=a[$1]";"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -F " " '{print $1"\t"$2","$3}' \
|awk -F "\t" '{if(a[$1])a[$1]=a[$1]":"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -v 'OFS=\t' '{print $1,$2,"Coding_upstream"}' | sort -k 1,1 > src/anno/peaks_class2.txt

intersectBed -s -wa -wb -a src/anno/peaks_nonClass1.bed -b src/anno/Coding-up_trimmed.bed -v > src/anno/peaks_nonClass2.bed
intersectBed -s -wa -wb -a src/anno/peaks_nonClass2.bed -b src/anno/Coding-CDS.bed | awk -F "\t" '{print($4,$10)}' \
|awk -F "|" '{if(a[$1])a[$1]=a[$1]";"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -F " " '{print $1"\t"$2","$3}' \
|awk -F "\t" '{if(a[$1])a[$1]=a[$1]":"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -v 'OFS=\t' '{print $1,$2,"Coding_CDS"}' | sort -k 1,1 > src/anno/peaks_class3.txt

intersectBed -s -wa -wb -a src/anno/peaks_nonClass2.bed -b src/anno/Coding-CDS.bed -v > src/anno/peaks_nonClass3.bed
intersectBed -s -wa -wb -a src/anno/peaks_nonClass3.bed -b src/anno/Coding-3UTR.bed | awk -F "\t" '{print($4,$10)}' \
|awk -F "|" '{if(a[$1])a[$1]=a[$1]";"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -F " " '{print $1"\t"$2","$3}' \
|awk -F "\t" '{if(a[$1])a[$1]=a[$1]":"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -v 'OFS=\t' '{print $1,$2,"Coding_3UTR"}' | sort -k 1,1 > src/anno/peaks_class4.txt

intersectBed -s -wa -wb -a src/anno/peaks_nonClass3.bed -b src/anno/Coding-3UTR.bed -v > src/anno/peaks_nonClass4.bed
intersectBed -s -wa -wb -a src/anno/peaks_nonClass4.bed -b src/anno/NC-1stexon.bed | awk -F "\t" '{print($4,$10)}' \
|awk -F "|" '{if(a[$1])a[$1]=a[$1]";"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -F " " '{print $1"\t"$2","$3}' \
|awk -F "\t" '{if(a[$1])a[$1]=a[$1]":"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -v 'OFS=\t' '{print $1,$2,"Noncoding_1st-exon"}' | sort -k 1,1 > src/anno/peaks_class5.txt

intersectBed -s -wa -wb -a src/anno/peaks_nonClass4.bed -b src/anno/NC-1stexon.bed -v > src/anno/peaks_nonClass5.bed
intersectBed -s -wa -wb -a src/anno/peaks_nonClass5.bed -b src/anno/NC-up_trimmed.bed | awk -F "\t" '{print($4,$10)}' \
|awk -F "|" '{if(a[$1])a[$1]=a[$1]";"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -F " " '{print $1"\t"$2","$3}' \
|awk -F "\t" '{if(a[$1])a[$1]=a[$1]":"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -v 'OFS=\t' '{print $1,$2,"Noncoding_upstream"}' | sort -k 1,1 > src/anno/peaks_class6.txt

intersectBed -s -wa -wb -a src/anno/peaks_nonClass5.bed -b src/anno/NC-up_trimmed.bed -v > src/anno/peaks_nonClass6.bed
intersectBed -s -wa -wb -a src/anno/peaks_nonClass6.bed -b src/anno/NC-exon.bed | awk -F "\t" '{print($4,$10)}' \
|awk -F "|" '{if(a[$1])a[$1]=a[$1]";"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -F " " '{print $1"\t"$2","$3}' \
|awk -F "\t" '{if(a[$1])a[$1]=a[$1]":"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -v 'OFS=\t' '{print $1,$2,"Noncoding_other-exon"}' | sort -k 1,1 > src/anno/peaks_class7.txt

intersectBed -s -wa -wb -a src/anno/peaks_nonClass6.bed -b src/anno/NC-exon.bed -v > src/anno/peaks_nonClass7.bed
intersectBed -s -wa -wb -a src/anno/peaks_nonClass7.bed -b src/anno/Intron.bed | awk -F "\t" '{print($4,$10)}' \
|awk -F "|" '{if(a[$1])a[$1]=a[$1]";"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -F " " '{print $1"\t"$2","$3}' \
|awk -F "\t" '{if(a[$1])a[$1]=a[$1]":"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' OFS="\t" \
|awk -v 'OFS=\t' '{print $1,$2,"Intron"}' | sort -k 1,1 > src/anno/peaks_class8.txt

intersectBed -s -wa -wb -a src/anno/peaks_nonClass7.bed -b src/anno/Intron.bed -v > src/anno/peaks_nonClass8.bed
cat src/anno/peaks_nonClass8.bed | awk -v 'OFS=\t' '{print($4,$1":"$3";"$6,"Unannotated")}' > src/anno/peaks_class9.txt

for i in {1..9}; do
cat src/anno/peaks_class${i}.txt 
done | sort -k 1,1 > byTFE_out/${OUTPUT_NAME}_annotation.txt

join -1 4 -2 4 -t "$(printf '\011')" <(sort -k 4,4 byTFE_out/${OUTPUT_NAME}_TFE-regions.bed) <(sort -k 4,4 byTFE_out/${OUTPUT_NAME}_peaks.bed) | awk 'BEGIN{OFS="\t"}{print $1,$2,$3,$4,$9,$6}' > byTFE_out/${OUTPUT_NAME}_TFE-region-peak.txt
join -1 1 -2 1 -t "$(printf '\011')" <(sort -k 1,1 byTFE_out/${OUTPUT_NAME}_annotation.txt) <(sort -k 1,1 byTFE_out/${OUTPUT_NAME}_TFE-region-peak.txt) > byTFE_out/${OUTPUT_NAME}_TFE-region-peak-anno.txt
join -1 1 -2 1 -t "$(printf '\011')" <(echo -e "Geneid""\t""Gene""\t""Annotation""\t""Chr""\t""Start""\t""End""\t""Peak""\t""Strand"| cat - <(sort -k 1,1 byTFE_out/${OUTPUT_NAME}_TFE-region-peak-anno.txt)) <(cat byTFE_out/${OUTPUT_NAME}_byTFE-counts.txt | sed -e '1d' | awk 'NR<2{print $0;next}{print $0| "sort -k 1,1"}') | cut -f-8,13- | awk 'NR<2{print $0;next}{print $0| "sort -k4,4 -k5,5n -k8,8"}' | sed -e "1 s/Geneid/TFE/g" | sed -e "1 s/forTFE\///g" | sed -e "1 s/.output.bam//g" > byTFE_out/${OUTPUT_NAME}_byTFE-counts_annotation.txt

rm byTFE_out/${OUTPUT_NAME}_TFE-region-peak.txt
rm byTFE_out/${OUTPUT_NAME}_TFE-region-peak-anno.txt
