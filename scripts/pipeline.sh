#!/bin/bash

#Download all the files specified in data/filenames
echo "##############################################"
echo "# START"
echo "##############################################"

# SOLUCION BONUS 2
echo "#---------------------------------------------"
echo "# Checking in output already exists"
echo "#---------------------------------------------"

if [ -d "./out/" ]; then
	echo "Output directory already exists."
else
	echo "Output directory does not exist."
fi

echo "#---------------------------------------------"
echo "# Downloading"
echo "#---------------------------------------------"

# SOLUCION ORIGINAL
#for url in $(cat ./data/urls) 
#do
#    bash scripts/download.sh $url data
#done

# SOLUCION BONUS 1
wget -P ./data -i ./data/urls


echo "#---------------------------------------------"
echo "# Download the contaminants fasta file, and uncompress it"
echo "#---------------------------------------------"
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes
echo "#---------------------------------------------"
echo "# Index the contaminants file"
echo "#---------------------------------------------"
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx
echo "#---------------------------------------------"
echo "# Merge the samples into a single file"
echo "#---------------------------------------------"
for sid in $(ls data/*.fastq.gz | sed 's:data/::')
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done
echo "#---------------------------------------------"
echo "# run cutadapt for all merged files"
echo "#---------------------------------------------"
mkdir -p log/cutadapt
mkdir -p out/trimmed
for sid in $(ls out/merged/*.gz | sed 's:out/merged/::')
do
	cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed -o out/trimmed/`echo $sid | cut -d"." -f1`.trimmed.fastq.gz out/merged/$sid > log/cutadapt/`echo $sid | cut -d"." -f1`.log
done
echo "#---------------------------------------------"
echo "# STAR for all trimmed files"
echo "#---------------------------------------------"
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
     sid=`basename $fname .trimmed.fastq.gz`
     outdir=out/star/$sid
     mkdir -p $outdir
     STAR --runThreadN 4 --genomeDir res/contaminants_idx --outReadsUnmapped Fastx --readFilesIn $fname --readFilesCommand zcat --outFileNamePrefix $outdir/
done


# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
echo "#---------------------------------------------"
echo "# Concatenate log files...";
echo "#---------------------------------------------"
find ./log/ -name "*.log" | xargs grep -P "(Reads with adapters|Total basepairs processed)" >> LogAgregado.out
find ./out/star/ -name "Log.final.out" | xargs grep -P "(Uniquely mapped reads %|% of reads mapped to multiple loci|% of reads mapped to too many loci)" >> LogAgregado.out

echo "##############################################"
echo "# END"
echo "##############################################"
