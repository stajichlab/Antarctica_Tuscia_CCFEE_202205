#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 2 --mem 4gb --out logs/stats.log

module load AAFTF

SAMPLES=samples.csv
INDIR=asm
OUTDIR=genomes

mkdir -p $OUTDIR
IFS=, # set the delimiter to be ,
tail -n +2 $SAMPLES | while read ID SAMPID BASE SAMPIDCC SPECIES PHYLUM STRAIN GEOLOC LAT LONG
do
    for type in AAFTF shovill
    do
	if [ ! -f $INDIR/$type/$STRAIN.sorted.fasta ]; then
		continue
	fi
	rsync -a $INDIR/$type/$STRAIN.sorted.fasta $OUTDIR/$STRAIN.$type.fasta
	if [[ ! -f $OUTDIR/$STRAIN.$type.stats.txt || $OUTDIR/$STRAIN.$type.fasta -nt $OUTDIR/$STRAIN.$type.stats.txt ]]; then
    	    AAFTF assess -i $OUTDIR/$STRAIN.$type.fasta -r $OUTDIR/$STRAIN.$type.stats.txt
	fi
    done
done
