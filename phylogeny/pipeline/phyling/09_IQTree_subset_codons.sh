#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 6 --mem 96gb --time 7-0:00:00 -p intel --out logs/iqtree_CDS.%A.log
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi

module load iqtree/2.2.0
mkdir phylo
pushd phylo
NUM=$(wc -l ../prefix.tab | awk '{print $1}')
source ../config.txt

ALN=../$PREFIX.subset.${NUM}_taxa.$HMM.cds.fasaln
PART=../$PREFIX.subset.${NUM}_taxa.$HMM.cds.partitions.txt
cp $PART .
PART=$(basename $PART)
perl -ip -e 's/^DNA/CODON/' $PART
iqtree2 -s $ALN --prefix $PREFIX.subset.${NUM}_taxa.$HMM.cds -T AUTO --threads-max $CPU -p $PART -m TESTMERGE -rcluster 10
