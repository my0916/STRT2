# TFE-based analysis

TFE (transcript far 5'-end)-based analysis employed in [Töhönen et al. 2015](https://doi.org/10.1038/ncomms9207). TFEs are defined as the first exon (5'-end region) of assembled STRT reads (transcripts) mapped to genome.  

## Dependencies
- [StringTie](https://ccb.jhu.edu/software/stringtie/)
- [SAMtools](http://samtools.sourceforge.net/)
- [bedtools](https://bedtools.readthedocs.io/en/latest/)
- [Subread](http://subread.sourceforge.net/)

## Requirements
- Source files (in `src` directory)
  - `TFEclass.txt` : Sample classification with barcode name (1-48) which is used for the transcript assembly. Please set "NA" for those samples that are not used for further analysis (e.g. negative controls or outlier samples). In the default settings, all samples are classfied as the same class.
  ### Example
    | 1 | classA | 
    | 2 | classB | 
    | 3 | classC | 
    | 4 | classA | 
    | 5 | classB | 
    | 6 | classC | 
    | 7 | classA | 
    | 8 | classB | 
    | 9 | classC | 
  In this case, transcript assembly is performed using samples 1, 4, 7 for classA, 2, 5, 8 for classB, and 3, 6, 9 for classC. Then first exons are collected from all thse 3 classes and annotated as TFEs.  
  
## Example usage
```
./STRT2-TFE.sh
```
For UPPMAX:
```
sbatch -A snic2017-7-317 -p core -n 8 -t 24:00:00 ./STRT2-TFE-UPPMAX.sh
```

## Parameters
- __Optional__

   | Name&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|Default value|Description|
   | :--- | :--- | :--- |
   | `-o, --out` | OUTPUT | Output file name. Please use __the identical name used in the pipeline__ (STRT2.sh or STRT2-UPPMAX.sh)|
   | `-c, --coverage` | 5 | Minimum read coverage allowed for the predicted transcripts used in StringTie.|
   | `-l, --length` | 74 | Minimum length allowed for the predicted transcripts used in StringTie.|
   | `-h, --help`| | Show usage.|
   | `-v, --version`| | Show version.|


