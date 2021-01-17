# 1KG_pahse3_data

export REF="/data/share/1KG/b37/b37.vcf/chr${1}.1kg.phase3.v5a.b37.vcf.gz" # for alignment

# work starts from here
export START="/home/chi/Imputation/data"

cd $START
grep \# genotype.vcf > Chr$1.vcf
grep -P ^$1\\t genotype.vcf >> Chr$1.vcf
mkdir Chr$1
cd Chr$1

# vcf -> plink
plink2 --vcf ../Chr$1.vcf --vcf-half-call 'm' --make-bed --out Chr
rm ../Chr$1.vcf

# alignment
java -Xmx40g -jar /home/chi/tools/GenotypeHarmonizer-1.4.23/GenotypeHarmonizer.jar PLINK_BED --input Chr --update-id --outputType PLINK_BED  --output Chr_align --refType VCF --ref $REF
echo '##########'
echo 'alignment done'
echo '##########'
# phasing
plink --bfile Chr_align --geno 0.02 --make-bed --out Chr_miss
plink --bfile Chr_miss --recode vcf-iid --out Chr_align_qc
shapeit --input-vcf Chr_align_qc.vcf -M /data/share/1KG/chrX/genetic_map_chr$1_nonPAR_combined_b37.txt  -O Chr_phased --force
echo '##########'
echo 'phasing done'
echo '##########'
# impute
python3 /home/chi/Imputation/scripts/add_gender_info.py -g ../sample_status.csv -s ./Chr_phased.sample

impute2 -chrX -m /data/share/1KG/chrX/genetic_map_chrX_PAR1_combined_b37.txt -h /data/share/1KG/chrX/1000GP_Phase3_chr$1_PAR1.hap.gz -l /data/share/1KG/chrX/1000GP_Phase3_chr$1_PAR1.legend.gz -known_haps_g Chr_phased.haps -sample_g Chr_phased.sample -int 1 900000 -Ne 20000  -o Chr_1_1

impute2 -chrX -m /data/share/1KG/chrX/genetic_map_chrX_PAR1_combined_b37.txt -h /data/share/1KG/chrX/1000GP_Phase3_chr$1_PAR1.hap.gz -l /data/share/1KG/chrX/1000GP_Phase3_chr$1_PAR1.legend.gz -known_haps_g Chr_phased.haps -sample_g Chr_phased.sample -int 900000 1800000 -Ne 20000  -o Chr_1_2

impute2 -chrX -m /data/share/1KG/chrX/genetic_map_chrX_PAR1_combined_b37.txt -h /data/share/1KG/chrX/1000GP_Phase3_chr$1_PAR1.hap.gz -l /data/share/1KG/chrX/1000GP_Phase3_chr$1_PAR1.legend.gz -known_haps_g Chr_phased.haps -sample_g Chr_phased.sample -int 1800000 2699507 -Ne 20000  -o Chr_1_3

cat Chr_1_1 Chr_1-2 Chr_1_3 > Chr_1

echo '##########'
echo 'impute part1 done'
echo '##########'
impute2 -chrX -m /data/share/1KG/chrX/genetic_map_chr$1_PAR2_combined_b37.txt -h /data/share/1KG/chrX/1000GP_Phase3_chr$1_PAR2.hap.gz -l /data/share/1KG/chrX/1000GP_Phase3_chr$1_PAR2.legend.gz -known_haps_g Chr_phased.haps -sample_g Chr_phased.sample -int 154933254 155260478 -Ne 20000 -allow_large_regions -o Chr_3
echo '##########'
echo 'impute part 3 done'
echo '##########'
impute2 -chrX -m /data/share/1KG/chrX/genetic_map_chr$1_nonPAR_combined_b37.txt -h /data/share/1KG/chrX/1000GP_Phase3_chr$1_NONPAR.hap.gz -l /data/share/1KG/chrX/1000GP_Phase3_chr$1_NONPAR.legend.gz -known_haps_g Chr_phased.haps -sample_g Chr_phased.sample -int 154699520 154930725 -Ne 20000 -allow_large_regions -o Chr_2_153

for i in {1..152}; 
do 
	impute2 -chrX -m /data/share/1KG/chrX/genetic_map_chr$1_nonPAR_combined_b37.txt -h /data/share/1KG/chrX/1000GP_Phase3_chr$1_NONPAR.hap.gz -l /data/share/1KG/chrX/1000GP_Phase3_chr$1_NONPAR.legend.gz -known_haps_g Chr_phased.haps -sample_g Chr_phased.sample -int $((i*1000000+2699520-1000000)) $((i*1000000+2699520)) -Ne 20000 -allow_large_regions -o Chr_2_$i
done

echo '##########'
echo 'impute part2 done'
echo '##########'

for i in {1..153}; do cat Chr_2_$i >> Chr_2; done
cat Chr_1 Chr_2 Chr_3 > Chr_ipt.gen
# srun python3 /public/home/cdjykj/impute_test/scripts/gen2vcf.py -i Chr_ipt.gen -s Chr_phased.sample -o ../imputed/Chr$1_ipt.vcf
cp Chr_ipt.gen ../imputed/Chr$1_ipt.gen
echo '##########'
echo 'the output is Chr_ipt$1.vcf'
echo '#########'
