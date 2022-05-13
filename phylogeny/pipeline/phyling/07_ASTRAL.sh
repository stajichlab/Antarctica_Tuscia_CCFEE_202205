#!/usr/bin/bash -l
#SBATCH -p intel -N 1 -n 2 --mem 64gb --out logs/ASTRAL.log

source config.txt

NUM=$(wc -l prefix.tab | awk '{print $1}')
MEM=64g
module load java
module load ASTRAL

# usethe subset folder instead

CDSGENETREES=${PREFIX}.subset.${NUM}_taxa.$HMM.CDS.gene_trees.tre
PEPGENETREES=${PREFIX}.subset.${NUM}_taxa.$HMM.aa.gene_trees.tre
CDSCONSTREE=$(basename $CDSGENETREES .gene_trees.tre)".astral.tre"
PEPCONSTREE=$(basename $PEPGENETREES .gene_trees.tre)".astral.tre"

if [ ! -f $CDSGENETREES ]; then
    cat bestgenes/CDS/*.cds.clipkit.FT.tre > $CDSGENETREES
fi

if [ ! -f $PEPGENETREES ]; then
    cat bestgenes/PEP/*.aa.clipkit.FT.tre > $PEPGENETREES
fi

echo "$CDSGENETREES -o $CDSCONSTREE"

if [ ! -s $CDSCONSTREE ]; then
    java -Xmx${MEM} -jar $ASTRALJAR -i $CDSGENETREES -o $CDSCONSTREE
fi

echo " -i $PEPGENETREES -o $PEPCONSTREE"
if [ ! -s $PEPCONSTREE ]; then
    java -Xmx${MEM} -jar $ASTRALJAR -i $PEPGENETREES -o $PEPCONSTREE
fi
conda activate /bigdata/stajichlab/shared/condaenv/phyling

perl PHYling_unified/util/rename_tree_nodes.pl $PEPCONSTREE prefix.tab > $(basename $PEPCONSTREE .tre).long.tre
perl PHYling_unified/util/rename_tree_nodes.pl $CDSCONSTREE prefix.tab > $(basename $CDSCONSTREE .tre).long.tre

