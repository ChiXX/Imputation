# 1KG_pahse3_data

export REF="/data/share/1KG/b37/b37.vcf/chr${1}.1kg.phase3.v5a.b37.vcf.gz" # for alignment
export MAP="/data/share/1KG/1000GP_Phase3/genetic_map_chr${1}_combined_b37.txt"
export HAP="/data/share/1KG/1000GP_Phase3/1000GP_Phase3_chr${1}.hap.gz"
export LEGEND="/data/share/1KG/1000GP_Phase3/1000GP_Phase3_chr${1}.legend.gz"

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
shapeit --input-vcf Chr_align_qc.vcf -M $MAP  -O Chr_phased --force
echo '##########'
echo 'phasing done'
echo '##########'
# impute

export Length=`zcat $LEGEND | tail -1 | cut -d " " -f2`
export loop=$((Length/1000000))
echo $Length
echo $loop

for ((i=1; i<=loop; i++));
do 
	impute2 -m $MAP -h $HAP -l $LEGEND -known_haps_g Chr_phased.haps -int $((i*1000000-1000000+1)) $((i*1000000)) -Ne 20000 -allow_large_regions -o Chr_$i
done

impute2 -m $MAP -h $HAP -l $LEGEND -known_haps_g Chr_phased.haps -int $((loop*1000000)) $Length -Ne 20000 -allow_large_regions -o Chr_$((loop+1))
echo '##########'
echo 'imputation done'
echo '##########'

for ((i=0; i<=loop; i++)); do cat Chr_$((i+1)) >> Chr_ipt.gen; done
# srun python3 /public/home/cdjykj/impute_test/scripts/gen2vcf.py -i Chr_ipt.gen -s Chr_phased.sample -o ../imputed/Chr$1_ipt.vcf
cp Chr_ipt.gen ../imputed/Chr$1_ipt.gen
echo '##########'
echo 'the output is Chr$1_ipt.vcf'
echo '##########'
