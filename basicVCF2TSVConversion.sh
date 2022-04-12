#!/usr/bin/env bash

#SBATCH --time=1-00:00:00
#SBATCH --nodes=1
#SBATCH -e ./vcf2tsv-%j-%N.err
#SBATCH -o ./vcf2tsv-%j-%N.out
#SBATCH --mail-user=brady.neeley@hsc.utah.edu
#SBATCH --mail-type=END
#SBATCH --account=pezzolesi-np
#SBATCH --partition=pezzolesi-np


# $1 is the first argument after the name of the script you're running (e.g. sbatch convertVCFtoTSV.sh
# THIS/PATH/GETS/PUT/INTO/$1)
vcf=$1
# get the directory that the vcf you want to convert lives in
out=$(dirname $vcf)

echo "User given vcf to convert to tsv: $vcf..."
echo "Directory used for output: ${out}/tsv/..."


# get the name of directory you want to convert without its path
f=$(basename $1)
# break the file name into bits with "." as the delimeter; stuff the resulting bits into an array
IFS="." read -ra fname <<< $f

# decompress the target vcf
# (I have my own installation of bgzip used here added to path variable)
bgzip -dc $vcf > $out/${fname[0]}.vcf

mkdir -p $out/tsv

# I installed vcf2tsv into a conda env here is how:
#   conda create --name working
#   conda activate working
#   conda install -c bioconda vcflib

# convert the target vcf to a tsv
vcf2tsv $out/${fname[0]}.vcf > $out/tsv/${fname[0]}_vcf2tsv.tsv
vcf2tsv -g $out/${fname[0]}.vcf > $out/tsv/${fname[0]}_perSample.tsv

rm $out/${fname[0]}.vcf
