# 1KG_pahse3_data

export REF="/public/home/cdjykj/tools/Beagle5.1/database/chr${1}.1kg.phase3.v5a.b37.vcf.gz" # for alignment
export MAP="/public/home/cdjykj/tools/impute_v2.3.2_x86_64_static/database/1000GP_Phase3/genetic_map_chr${1}_combined_b37.txt"
export HAP="/public/home/cdjykj/tools/impute_v2.3.2_x86_64_static/database/1000GP_Phase3/1000GP_Phase3_chr${1}.hap.gz"
export LEGEND="/public/home/cdjykj/tools/impute_v2.3.2_x86_64_static/database/1000GP_Phase3/1000GP_Phase3_chr${1}.legend.gz"

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
srun java -Xmx40g -jar /public/home/cdjykj/tools/GenotypeHarmonizer-1.4.23/GenotypeHarmonizer.jar --inputType PLINK_BED --input Chr --update-id --outputType PLINK_BED  --output Chr_align --refType VCF --ref $REF
echo '##########'
echo 'alignment done'
echo '##########'
# phasing
srun plink --bfile Chr_align --geno 0.02 --make-bed --out Chr_miss
srun plink --bfile Chr_miss --recode vcf-iid --out Chr_align_qc
srun shapeit --input-vcf Chr_align_qc.vcf -M $MAP  -O Chr_phased --force
echo '##########'
echo 'phasing done'
echo '##########'
# impute

export Length=`zcat $LEGEND | tail -1 | cut -d " " -f2`
export loop=$((Length/10000000))
echo $Length
echo $loop

for ((i=1; i<=loop; i++)); do srun impute2 -m $MAP -h $HAP -l $LEGEND -known_haps_g Chr_phased.haps -int $((i*10000000-10000000+1)) $((i*10000000)) -Ne 20000 -allow_large_regions -o Chr_$i; done

srun impute2 -m $MAP -h $HAP -l $LEGEND -known_haps_g Chr_phased.haps -int $((loop*10000000)) $Length -Ne 20000 -allow_large_regions -o Chr_$((loop+1))
echo '##########'
echo 'imputation done'
echo '##########'

for ((i=0; i<=loop; i++)); do cat Chr_$((i+1)) >> Chr_ipt.gen; done
srun python3 /public/home/cdjykj/impute_test/scripts/gen2vcf.py -i Chr_ipt.gen -s Chr_phased.sample -o ../imputed/Chr$1_ipt.vcf
echo '##########'
echo 'the output is Chr$1_ipt.vcf'
echo '##########'
