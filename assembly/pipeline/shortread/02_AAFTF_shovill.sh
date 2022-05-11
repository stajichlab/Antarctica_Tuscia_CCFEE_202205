#!/bin/bash -l
#SBATCH --nodes 1 --ntasks 24 -p short --mem 128gb -J shovill --out logs/AAFTF_shovill.%a.log

# this load $SCRATCH variable
module load workspace/scratch
MEM=128
CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
 CPU=2
fi

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

OUTDIR=input

SAMPLEFILE=samples.csv
ASM=asm/shovill
MINLEN=500
FASTQ=input
WORKDIR=working_AAFTF
mkdir -p $ASM
IFS=, # set the delimiter to be ,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read ID SAMPID BASE SAMPIDCC SPECIES PHYLUM STRAIN GEOLOC LAT LONG
do
    ASMFILE=$ASM/${STRAIN}.spades.fasta
    ASMGFA=$ASM/${STRAIN}.spades.gfa.gz
    VECCLEAN=$ASM/${STRAIN}.vecscreen.fasta
    PURGE=$ASM/${STRAIN}.sourpurge.fasta
    CLEANDUP=$ASM/${STRAIN}.rmdup.fasta
    PILON=$ASM/${STRAIN}.pilon.fasta
    SORTED=$ASM/${STRAIN}.sorted.fasta
    STATS=$ASM/${STRAIN}.sorted.stats.txt
    LEFTIN=$FASTQ/${BASE}_R1_001.fastq.gz
    RIGHTIN=$FASTQ/${BASE}_R2_001.fastq.gz

    if [ ! -f $LEFTIN ]; then
	echo "no $LEFTIN file for $STRAIN/$BASE in $FASTQ dir"
	exit
    fi
    LEFTTRIM=$WORKDIR/${BASE}_1P.fastq.gz
    RIGHTTRIM=$WORKDIR/${BASE}_2P.fastq.gz
    LEFTF=$WORKDIR/${BASE}_filtered_1.fastq.gz
    RIGHTF=$WORKDIR/${BASE}_filtered_2.fastq.gz
    LEFT=$WORKDIR/${BASE}_fastp_1.fastq.gz
    RIGHT=$WORKDIR/${BASE}_fastp_2.fastq.gz

    echo "$BASE $STRAIN"

    if [ ! -s $ASMFILE ]; then
	if [ ! -f $LEFT ]; then
	    module load AAFTF
	    module load fastp
	    if [ ! -f $LEFTF ]; then # can skip filtering if this exists means already processed
		if [ ! -f $LEFTTRIM ]; then
		    AAFTF trim --method bbduk --memory $MEM --left $LEFTIN --right $RIGHTIN -c $CPU -o $WORKDIR/${BASE}
		fi
		AAFTF filter -c $CPU --memory $MEM -o $WORKDIR/${BASE} --left $LEFTTRIM --right $RIGHTTRIM --aligner bbduk
		if [ -f $LEFTF ]; then
		    #rm $LEFTTRIM $RIGHTTRIM # remove intermediate file
		    echo "found $LEFTF"
		fi
	    fi
	    fastp --in1 $LEFTF --in2 $RIGHTF --out1 $LEFT --out2 $RIGHT -w $CPU --dedup \
		  --dup_calc_accuracy 6 -y --detect_adapter_for_pe \
		  -j $WORKDIR/${BASE}.json -h $WORKDIR/${BASE}.html
	    module unload fastp
	    module unload AAFTF
	fi
	module load shovill
	time shovill --cpu $CPU --ram $MEM --outdir $WORKDIR/shovill_${STRAIN} \
		--R1 $LEFT --R2 $RIGHT --nocorr --depth 90 --tmpdir $SCRATCH --minlen $MINLEN
	module unload shovill
	if [ -f $WORKDIR/shovill_${STRAIN}/contigs.fa ]; then
	    rsync -av $WORKDIR/shovill_${STRAIN}/contigs.fa $ASMFILE
	    pigz -c $WORKDIR/shovill_${STRAIN}/contigs.gfa > $ASMGFA
	else	
	    echo "Cannot find $WORKDIR/shovill_${STRAIN}/contigs.fa"
	fi
	
	if [ -s $ASMFILE ]; then
	    rm -rf $WORKDIR/shovill_${STRAIN}
	else
	    echo "SPADES must have failed, exiting"
	    exit
	fi
    fi
    module load AAFTF
    
    if [ ! -f $VECCLEAN ]; then
	AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN 
    fi
    
    if [ ! -f $PURGE ]; then
	AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT  --right $RIGHT
    fi
    
    if [ ! -f $CLEANDUP ]; then
	AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m $MINLEN
    fi
    
#    if [ ! -f $PILON ]; then
#	AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT  --right $RIGHT 
#    fi
    
#    if [ ! -f $PILON ]; then
#	echo "Error running Pilon, did not create file. Exiting"
#	exit
#    fi
    
    if [ ! -f $SORTED ]; then
	AAFTF sort -i $CLEANDUP -o $SORTED
    fi
    
    if [ ! -f $STATS ]; then
	AAFTF assess -i $SORTED -r $STATS
    fi
done
