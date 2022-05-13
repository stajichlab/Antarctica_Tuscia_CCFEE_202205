#!/bin/bash -l
#SBATCH -p short -N 1 -n 64 --mem 96gb --out logs/phykit_summarize_pep.log

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi

source config.txt
PEPTREEEXT=aa.clipkit.FT.tre
mkdir -p gene_trees
pushd gene_trees
ln -s ../aln/$HMM/*.${PEPTREEEXT} .
ln -s ../aln/$HMM/*.$(basename $PEPTREEEXT .FT.tre) .
find -L . -size 0 | xargs rm

module load phykit
module load parallel
summarize() {
treefile=$(basename $1)
aln=$(basename $treefile .FT.tre)
len=$(phykit aln_len $aln)
bss=$(phykit bss $treefile)
evorate=$(phykit evolutionary_rate $treefile)
meanBSS=$(echo $bss | grep mean: | awk '{print $2}')
medianBSS=$(echo $bss | grep median: | awk '{print $2}')
echo -e "$treefile\t$aln\t$len\t$meanBSS\t$medianBSS\t$evorate"
}
export -f summarize
echo -e "TREE\tALN\tALNLEN\tmean_BSS\tmedian_BSS\tevoRate" > ../gene_trees.summarize_PEP.tsv
parallel -j $CPU summarize ::: $(find . -name "*.${PEPTREEEXT}" ) >> ../gene_trees.summarize_PEP.tsv
