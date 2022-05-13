#!/bin/bash -l
#SBATCH -p short -N 1 -n 128 --mem 96gb  -N 1 --out logs/make_CDS_trees.%A.log
module load fasttree
module load IQ-TREE/2.1.1

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi

make -f PHYling_unified/util/makefiles/Makefile.trees HMM=sordariomycetes_odb10.2021 -j $CPU CDS
