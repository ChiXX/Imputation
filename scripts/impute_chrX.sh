#!/bin/bash
#SBATCH -p normal
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
#SBATCH -o /public/home/cdjykj/impute_test/info/chrX.sh.o
#SBATCH -e /public/home/cdjykj/impute_test/info/chrX.sh.e

# 1KG_pahse3_data

export REF="/public/home/cdjykj/tools/Beagle5.1/database/chr${1}.1kg.phase3.v5a.b37.vcf.gz" # for alignment

# work starts from here
export START="/public/home/cdjykj/impute_test/data"

cd $START
grep \# genotype.vcf > Chr$1.vcf
grep -P ^$1\\t genotype.vcf >> Chr$1.vcf
mkdir Chr$1
cd Chr$1

# vcf -> plink
srun plink2 --vcf ../Chr$1.vcf --vcf-half-call 'm' --make-bed --out Chr
rm ../Chr$1.vcf

# alignment
srun java -Xmx40g -jar /public/home/cdjykj/tools/GenotypeHarmonizer-1.4.23/GenotypeHarmonizer.jar PLINK_BED --input Chr --update-id --outputType PLINK_BED  --output Chr_align --refType VCF --ref $REF
echo '##########'
echo 'alignment done'
echo '##########'
# phasing
srun plink --bfile Chr_align --geno 0.02 --make-bed --out Chr_miss
srun plink --bfile Chr_miss --recode vcf-iid --out Chr_align_qc
srun shapeit --input-vcf Chr_align_qc.vcf -M ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chr$1_nonPAR_combined_b37.txt  -O Chr_phased --force
echo '##########'
echo 'phasing done'
echo '##########'
# impute
srun python3 /public/home/cdjykj/impute_test/scripts/add_gender_info.py -g ../sample_status.csv -s ./Chr_phased.sample
srun impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chr$1/genetic_map_chrX_PAR1_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chr$1_PAR1.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chr$1_PAR1.legend.gz -known_haps_g Chr_phased.haps -sample_g Chr_phased.sample -int 1 2699507 -Ne 20000  -o Chr_1
echo '##########'
echo 'impute part1 done'
echo '##########'
srun impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chr$1_PAR2_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chr$1_PAR2.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chr$1_PAR2.legend.gz -known_haps_g Chr_phased.haps -sample_g Chr_phased.sample -int 154933254 155260478 -Ne 20000 -allow_large_regions -o Chr_3
echo '##########'
echo 'impute part 3 done'
echo '##########'
srun impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chr$1_nonPAR_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chr$1_NONPAR.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chr$1_NONPAR.legend.gz -known_haps_g Chr_phased.haps -sample_g Chr_phased.sample -int 142699520 154930725 -Ne 20000 -allow_large_regions -o Chr_2_15

for i in {1..14}; do srun impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chr$1_nonPAR_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chr$1_NONPAR.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chr$1_NONPAR.legend.gz -known_haps_g Chr_phased.haps -sample_g Chr_phased.sample -int $((i*10000000+2699520-10000000)) $((i*10000000+2699520)) -Ne 20000 -allow_large_regions -o Chr_2_$i; done
echo '##########'
echo 'impute part2 done'
echo '##########'

for i in {1..15}; do cat Chr_2_$i >> Chr_2; done
srun cat Chr_1 Chr_2 Chr_3 > Chr_ipt.gen
# srun python3 /public/home/cdjykj/impute_test/scripts/gen2vcf.py -i Chr_ipt.gen -s Chr_phased.sample -o ../imputed/Chr$1_ipt.vcf
cp Chr_ipt.gen ../imputed/Chr$1_ipt.gen
echo '##########'
echo 'the output is Chr_ipt$1.vcf'
echo '#########'
