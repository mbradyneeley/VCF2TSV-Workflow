#!/usr/bin/env bash

#SBATCH --time=1-00:00:00
#SBATCH --nodes=1
#SBATCH -e ./vcf2tsv-%j-%N.err
#SBATCH -o ./vcf2tsv-%j-%N.out
#SBATCH --mail-user=brady.neeley@hsc.utah.edu
#SBATCH --mail-type=END
#SBATCH --account=pezzolesi-np
#SBATCH --partition=pezzolesi-np

# Check that vcf2tsv is available as an executable on PATH
if ! command -v vcf2tsv &> /dev/null
then
    echo "
    vcf2tsv could not be found. Install or add to PATH variable.

    *Easily install vcf2tsv into a new conda env as follows:
     conda create --name working
     conda activate working
     conda install -c bioconda vcflib
    "
    exit
fi

# Include vcf as argument 1 when running script
vcf=$1

# Check that the variable vcf is not empty
if [[ -z "$vcf" ]]; 
then
    echo "No vcf included to convert to tsv."
    exit
fi

# Get the directory that the vcf you want to convert lives in
out=$(dirname $vcf)

echo "User given vcf to convert to tsv: $vcf..."
echo "Directory used for output: ${out}/tsv/..."


# get the name of vcf you want to convert without its path
f=$(basename $1)
# break the file name into bits with "." as the delimeter; stuff the resulting bits into an array
IFS="." read -ra fname <<< $f

# decompress the target vcf
# (I have my own installation of bgzip used here added to path variable)
bgzip -dc $vcf > $out/${fname[0]}.vcf

mkdir -p $out/tsv

# Keep only the annotations that Marcus usually likes to see endgame
bcftools annotate \
    -x ^INFO/AC,INFO/AN,INFO/AF,INFO/Func.refGene,INFO/Gene.refGene,INFO/GeneDetail.refGene,INFO/ExonicFunc.refGene,INFO/AAChange.refGene,INFO/SIFT_pred,INFO/LRT_pred,INFO/MutationTaster_pred,INFO/MutationAssessor_pred,INFO/PROVEAN_pred,INFO/MetaSVM_pred,INFO/MetaLR_pred,INFO/MCAP_pred,INFO/GERP_RS,INFO/GERP_RS_rankscore,INFO/Polyphen2_HDIV_pred,INFO/Polyphen2_HVAR_pred,INFO/CADD_phred,INFO/REVEL,INFO/Interpro_domain,INFO/avsnp150,INFO/CLNDN,%INFO/CLNSIG,INFO/combined_AF_nfe,INFO/combined_AF_all,^FORMAT/GT \
    -o $out/${fname[0]}_annotations.vcf \
    $out/${fname[0]}.vcf

# convert the target vcf to a tsv
vcf2tsv $out/${fname[0]}_annotations.vcf > $out/tsv/${fname[0]}_vcf2tsv.tsv
vcf2tsv -g $out/${fname[0]}_annotations.vcf > $out/tsv/${fname[0]}_perAllSamples.tsv

# Only keep samples that are het or homozyg for the alt allele
head -1 $out/tsv/${fname[0]}_perAllSamples.tsv > $out/tsv/${fname[0]}_perSample.tsv
grep "0/1\|1/1" $out/tsv/${fname[0]}_perAllSamples.tsv >> $out/tsv/${fname[0]}_perSample.tsv

# Remove intermediate files
rm $out/${fname[0]}.vcf
rm $out/${fname[0]}_annotations.vcf
rm $out/tsv/${fname[0]}_perAllSamples.tsv

echo "VCF conversion to TSV succesful"
