# This script should merge all files from a given sample (the sample id is provided in the third argument)
# into a single file, which should be stored in the output directory specified by the second argument.
# The directory containing the samples is indicated by the first argument.
if [ "$#" -eq 3 ]; then
	mkdir -p $2
	cat $1/$3 >> $2/"`echo $3 | cut -d "-" -f1 | sed 's:data/::'`"".fastq.gz"
fi
