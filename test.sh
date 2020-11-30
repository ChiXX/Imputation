#!/bin/bash
#SBATCH -p normal
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
#SBATCH -o impute_chrX2.sh.o
#SBATCH -e impute_chrX2.sh.e

grep \# ./data/genotype.vcf > ./data/ChrX.vcf
grep '^X' ./data/genotype.vcf >> ./data/ChrX.vcf
mkdir ./data/ChrX2
cd ./data/ChrX2
mv ../ChrX.vcf ./

# cvf -> plink
srun plink2 --vcf ChrX.vcf --vcf-half-call 'm' --make-bed --out ChrX
# alignment
srun java -Xmx40g -jar ~/tools/GenotypeHarmonizer-1.4.23/GenotypeHarmonizer.jar --inputType PLINK_BED --input ChrX --update-id --outputType PLINK_BED  --output ChrX_align --refType VCF --ref ~/tools/Beagle5.1/database/chrX.1kg.phase3.v5a.b37.vcf.gz
echo '##########'
echo 'alignment done'
echo '##########'
# phasing
srun plink --bfile ChrX --geno 0.02 --make-bed --out ChrX_miss
srun plink --bfile ChrX_miss --recode vcf-iid --out ChrX_align_qc
srun shapeit --input-vcf ChrX_align_qc.vcf -M ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chrX_nonPAR_combined_b37.txt  -O ChrX_phased --force
echo '##########'
echo 'phasing done'
echo '##########'
# impute
srun python3 ../../scripts/add_gender_info.py -g ../sample_status.csv -s ./ChrX_phased.sample
srun impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chrX_PAR1_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_PAR1.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_PAR1.legend.gz -known_haps_g ChrX_phased.haps -sample_g ChrX_phased.sample -int 1 2699507 -Ne 20000  -o ChrX_1
echo '##########'
echo 'impute part1 done'
echo '##########'
srun impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chrX_PAR2_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_PAR2.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_PAR2.legend.gz -known_haps_g ChrX_phased.haps -sample_g ChrX_phased.sample -int 154933254 155260478 -Ne 20000 -allow_large_regions -o ChrX_3
echo '##########'
echo 'impute part 3 done'
echo '##########'
srun impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chrX_nonPAR_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_NONPAR.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_NONPAR.legend.gz -known_haps_g ChrX_phased.haps -sample_g ChrX_phased.sample -int 142699520 154930725 -Ne 20000 -allow_large_regions -o ChrX_2_15

for i in {1..14}; do srun impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chrX_nonPAR_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_NONPAR.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_NONPAR.legend.gz -known_haps_g ChrX_phased.haps -sample_g ChrX_phased.sample -int $((i*10000000+2699520-10000000)) $((i*10000000+2699520)) -Ne 20000 -allow_large_regions -o ChrX_2_$i; done
echo '##########'
echo 'impute part2 done'
echo '##########'

for i in {1..15}; do cat ChrX_2_$i >> ChrX_2; done
srun cat ChrX_1 ChrX_2 ChrX_3 > ChrX_ipt.gen
srun python3 ../../scripts/gen2vcf.py -i ChrX_ipt.gen -s ChrX_phased.sample -o ChrX_ipt.vcf
echo '##########'
echo 'the output is Chr_ipt.vcf'
echo '##########'
