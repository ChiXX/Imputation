## Imputation

In the computing sever:

```bash
sbatch run.sh
```

### 1. vcf file converting

My file looks like this:

|#CHROM|POS|ID|REF|INFO|CHIA-3|CHIA-4|......|
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | :--: |
|1|156084877|.|C|1:156084877;FWD|CC|CC|.....|
|1|156105743|rs1060502211|G|1:156105743;FWD|GG|GG|.....|


Which lack the **ALT** column. Genotype file should in [vcf](http://samtools.github.io/hts-specs/VCFv4.2.pdf) format, using ```./scripts/2vcf.py```to make this. 

```bash
python ./scripts/2vcf.py -r ./data/ASA_CHIA_ANNO_FINAL_1125.txt -i ./data/genotype.txt -o ./data/genotype.vcf -n 10
```

*notes:* 

* ALT could be same as REF
* locus could duplicate

### 2. quality control

```bash
mkdir QC
cd QC
```

Firstly, convert vcf file to binary plink format

```bash
plink2 --vcf ../genotype.vcf --allow-extra-chr --vcf-half-call 'm' --make-bed --out genotype
```

The './0' is specified as an error in plink, using `--vcf-half-call 'm'` to treat halfs as missing.

some R [scripts](https://github.com/MareesAT/GWA_tutorial)

Prior-QC is necessary for the next step has limitation on data quality.

#### 2.1 missingness 

```bash
# plot histogram of missing rate
mkdir miss
cd miss
plink --bfile ../genotype --missing
Rscript --no-save ../../../scripts/hist_miss.R

# Delete SNPs with missingness > 0.2
plink --bfile ../genotype --geno 0.2 --make-bed --out genotype_1
```

#### 2.2 minor allele frequency (MAF)

Generate a bfile with autosomal SNPs only.

```bash
mkdir maf
cd maf
awk '{ if ($1 >= 1 && $1 <= 22) print $2 }' ../miss/genotype_1.bim > snp_1_22.txt
plink --bfile ../miss/genotype_1 --extract snp_1_22.txt --make-bed --out genotype_2
```

check MAF distribution

```bash
plink --bfile genotype_2 --freq --out MAF_check
Rscript --no-save ../../../scripts/MAF_check.R
```

flitering

```bash
plink --bfile genotype_2 --maf 0.05 --make-bed --out genotype_3
```

#### 2.3 Hardy-Weinberg equilibrium (HWE)

Check the distribution of HWE p-values of all SNPs.

```bash
mkdir hwe
cd hwe
plink --bfile ../maf/genotype_3 --hardy
```

Selecting SNPs with HWE p-value below 0.00001, required for one of the two plot generated by the next Rscript, allows to zoom in on strongly deviating SNPs. 

```bash
awk '{ if ($9 <0.01) print $0 }' plink.hwe>plinkzoomhwe.hwe
Rscript --no-save ../../../scripts/hwe.R 
```

```bash
plink --bfile ../maf/genotype_3 --hwe 0.005 --make-bed --out genotype_4
```

convert to vcf format

```
plink --bfile genotype_4 --recode vcf-iid --out ../../genotype.qc
```

### 3. Imputation

Carry out 2 types of imputation. Step by step workflow is shown below.

#### 3.1 Impute with Beagle5.1

##### Step 1: Phasing

```bash
java -jar ./scripts/beagle.18May20.d20.jar gt=./data/genotype.qc.vcf out=./data/genotype.phased
```

##### Step 2: Consistency

Split the phased genotype file by chromosome with `./scripts/merge_and_split.py`

```bash
python3 ./scripts/merge_and_split.py -op s -i ./data/genotype.phased.vcf.gz -o ./data/vcfs
```

Download the [reference](http://bochet.gcc.biostat.washington.edu/beagle/1000_Genomes_phase3_v5a/) and adjust the target genomic position consistent with the reference with [conform-gt](http://faculty.washington.edu/browning/conform-gt.html). The [population](http://bochet.gcc.biostat.washington.edu/beagle/1000_Genomes_phase3_v5a/sample_info/integrated_call_samples_v3.20130502.ALL.panel) information of reference genotype is listed below:

```bash
# Download sample information for 1000 Genomes Project and changed to b37.info
wget http://bochet.gcc.biostat.washington.edu/beagle/1000_Genomes_phase3_v5a/sample_info/integrated_call_samples_v3.20130502.ALL.panel

# Download 1000 Genomes Project reference panel
wget http://bochet.gcc.biostat.washington.edu/beagle/1000_Genomes_phase3_v5a/b37.vcf
```

|  super_pop  | abbreviation |
| :---------: | :----------: |
| East Asian  |     EAS      |
| South Asian |     SAS      |
|   African   |     AFR      |
|  European   |     EUR      |
|  American   |     AMR      |

select Asian population

```bash
grep -E 'AFR|EUR|AMR' b37.info | cut -f1 > non.asian
mv non.asian ~/Imputation/data/vcfs
```

conform-gt usage:

```bash
ls /data/share/1KG/b37/b37.bref3 | cut -d '.' -f1 | while read line; do java -jar scripts/conform-gt.24May16.cee.jar ref=/data/share/1KG/b37/b37.vcf/chr${line:3}.1kg.phase3.v5a.b37.vcf.gz gt=./data/vcfs/chr${line:3}.vcf.gz chrom=${line:3} out=./data/vcfs/conform.chr${line:3} excludesamples=./data/vcfs/non.asian; done
```

*Hint*: Conversion between vcf and bref3 can be achieved with [bref3](http://faculty.washington.edu/browning/beagle/bref3.18May20.d20.jar) and [unbref3](http://faculty.washington.edu/browning/beagle/unbref3.18May20.d20.jar) as below:

```bash
ls * | cut -d '.' -f 1-5 | while read line; do java -jar ~/Imputation/scripts/unbref3.18May20.d20.jar $line.bref3 > ../b37.vcf/$line.vcf; done
```

##### Step 3: Imputation 

```bash
ls ./data/vcfs/conform.* | cut -d '.' -f3 | uniq | while read line; do java -jar ./scripts/beagle.18May20.d20.jar ref=/data/share/1KG/b37/b37.bref3/$line.1kg.phase3.v5a.b37.bref3 gt=./data/vcfs/conform.$line.vcf.gz out=./data/imputed/$line; done
```

Merge file

```bash
python3 ./scripts/merge_and_split.py -op m -i ./data/imputed -o ./data/genotype.imputed
```

#### 3.2 Impute with IMPUTE2

##### Step1: Alignment

Before VCF files can be used they need to be compressed using bgzip and indexed with tabix. 

[**Genotype Harmonizer**](https://github.com/molgenis/systemsgenetics/wiki/Genotype-Harmonizer) is an easy to use tool helping accomplish this job.

```bash
mkdir alignment
cd alignment
cp ../vcfs/chr10.vcf.gz
gzip -d chr10.vcf.gz

plink2 --vcf chr10.vcf -allow-extra-chr --vcf-half-call 'm' --make-bed --out chr10

java -Xmx40g -jar ~/tools/GenotypeHarmonizer-1.4.23/GenotypeHarmonizer.jar --inputType PLINK_BED --input chr10 --update-id --outputType PLINK_BED  --output ./chr10.align --refType VCF --ref /data/share/1KG/b37/b37.vcf/chr10.1kg.phase3.v5a.b37.vcf.gz
```

##### Step2: pre-phasing using SHAPEIT2

```bash
mkdir pre_phase
cd pre_phase

plink --bfile ../alignment/chr10.align --recode vcf-iid --out ./chr10.align
shapeit --input-vcf chr10.align.vcf -M /data/share/1KG/1000GP_Phase3/genetic_map_chr10_combined_b37.txt  -O phased_chr10
```

##### Step 3: Imputation

```bash
mkdir imputed2
cd imputed2

impute2 -use_prephased_g -Ne 20000 -iter 30 -align_by_maf_g -os 0 1 2 3 -int 1 3000000 -h /data/share/1KG/1000GP_Phase3/1000GP_Phase3_chr10.hap -l /data/share/1KG/1000GP_Phase3/1000GP_Phase3_chr10.legend -m /data/share/1KG/1000GP_Phase3/genetic_map_chr10_combined_b37.txt -known_haps_g ../pre_phase/phased_chr10.haps -o ./chr10_1

impute2 -use_prephased_g -Ne 20000 -iter 30 -align_by_maf_g -os 0 1 2 3 -int 3000000 6000000 -h /data/share/1KG/1000GP_Phase3/1000GP_Phase3_chr10.hap -l /data/share/1KG/1000GP_Phase3/1000GP_Phase3_chr10.legend -m /data/share/1KG/1000GP_Phase3/genetic_map_chr10_combined_b37.txt -known_haps_g ../pre_phase/phased_chr10.haps -o ./chr10_2

cat chr10_1 chr10_2 > chr10.gen
```

convert to vcf with [qctool](https://www.well.ox.ac.uk/~gav/qctool/index.html)

```bash
## impute with impute2
qctool -g chr10.gen -og chr10.ip2.vcf
```

##### Step 4: ChrX

The only difference in carrying out imputation between x chromosome and autosome is gender information should be added to `.sample` file, and `-chrx` and `-sample_g` flag should be specified.

```bash
impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chrX_PAR1_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_PAR1.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_PAR1.legend.gz -known_haps_g ChrX_phased.haps -sample_g ChrX_phased.sample -int 1 2699507 -Ne 20000  -o ChrX_1

nohup impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chrX_nonPAR_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_NONPAR.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_NONPAR.legend.gz -known_haps_g ChrX_phased.haps -sample_g ChrX_phased.sample -int 2699520 12699520 -Ne 20000 -allow_large_regions -o ChrX_2_1 &
...
nohup impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chrX_nonPAR_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_NONPAR.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_NONPAR.legend.gz -known_haps_g ChrX_phased.haps -sample_g ChrX_phased.sample -int 142699520 154930725 -Ne 20000 -allow_large_regions -o ChrX_2_15 &

impute2 -chrX -m ~/tools/impute_v2.3.2_x86_64_static/database/chrX/genetic_map_chrX_PAR2_combined_b37.txt -h ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_PAR2.hap.gz -l ~/tools/impute_v2.3.2_x86_64_static/database/chrX/1000GP_Phase3_chrX_PAR2.legend.gz -known_haps_g ChrX_phased.haps -sample_g ChrX_phased.sample -int 154933254 155260478 -Ne 20000 -allow_large_regions -o ChrX_3


touch chrX_2
for i in {1..15}; do cat ChrX_2_$i >> ChrX_2; done
cat ChrX_1 ChrX_2 ChrX_3 > ChrX_ipt.gen
# some libraries in centos don't match the requirements of qctool, so I writen one...
python3 ../../scripts/gen2vcf.py -i ChrX_ipt.gen -s ChrX_phased.sample -o ChrX_ipt.vcf
```

#### 3.3 comparison between two methods

To minimize the difference, using all ethnic as reference and  imputing with beagle on chr10.

```bash
## impute with beagle
java -jar ./scripts/beagle.18May20.d20.jar ref=/data/share/1KG/b37/b37.bref3/chr10.1kg.phase3.v5a.b37.bref3 gt=./data/vcfs/conform.chr10.vcf.gz out=./data/imputed/chr10.bg
```

```bash
mkdir comp
cd comp
cp ../imputed/chr10.bg.vcf.gz ./
cp ../imputed2/chr10.ip2.vcf ./
gzip chr10.ip2.vcf
```

description:

* in beagle imputation result, the in GT format agreeing with VCF4.2.
* in impute2 output, the result is converted from [gen file](https://cran.r-project.org/web/packages/BinaryDosage/vignettes/usinggenfiles.html), the genotype is stored as the genotype probabilities
  * The dosage value only
  * Probability subject has no alternate alleles, probability subject has one alternate allele.
  * Probability subject has no alternate alleles, probability subject has  one alternate allele, probability subject has two alternate allele.

```bash
# the file path has already been writen into script
python3 ./scripts/beagle_vs_impute2.py 
```

|Sample|Similarity|
|:--:|:--:|
|CHIA-1|0.9915399505012471|
|CHIA-2|0.989267245115128|
|CHIA-3|0.9902976666249362|
|CHIA-4|0.9924355505050991|
|CHIA-5|0.9893298408143218|
|CHIA-6|0.9884294257566857|
|CHIA-7|0.9896765246867808|
|CHIA-8|0.9933455956703037|
|CHIA-9|0.9921514623318343|
|CHIA-10|0.9870860257509076|

**Notes:** To make reference data suit for beagle5, the author [removed](http://bochet.gcc.biostat.washington.edu/beagle/1000_Genomes_phase3_v5a/1000G_READMEs/READ_ME_phase3_callset_20150220) some SNPs, which makes the amount of imputed SNPs different from the result of impute2. And with the limit of computer memory and the considering of calculation time, impute2 only uses the interval **from 1 to 18000000** of chr10 which is also applied on beagle result when comparison.  The locus with genotype possibility lower than 0.8 in impute2 result are removed. Overall, in target interval, beagle result has **242481** locus, impute2 has **579438** locus (after filtering), they have **207682** locus in common.

### 4. Wrapper

On [supercomputing machine](https://www.hpccube.com/ac/console/space/dashboard.jsp?reminder=1), wrapping all steps into one script, `run.sh`. This scripts is based on impute2, just run `sbatch` to submit the mission.

```bash
sbatch run.sh
```

## Association analysis

There are 22 samples in example data set. Firstly merge them into one VCF file, then split them by chromosome.

```bash
srun tabix -p vcf Sample1.g.vcf.gz
srun java -Xmx30G -Djava.io.tmpdir=/public/home/cdjykj/gwas_test/java_tmp -jar /public/home/cdjykj/tools/GenomeAnalysisTK-3.8-0-ge9d806836/GenomeAnalysisTK.jar -T GenotypeGVCFs -allSites -stand_call_conf 30 -R genome.fa --variant Sample33.g.vcf.gz -o Sample33.vcf.gz

# Incorrect number of FORMAT/AD values at 1:1, cannot merge. The tag is defined as Number=R, but found 2 values and 1 alleles.
# because some $PATH problem, bcftools is changed to bcf (version 1.9)
srun bcf annotate -x FORMAT/AD Sample11.vcf.gz -Oz -o Sample11.vcf.gz
srun -p normal ls *vcf.gz | while read line; do bcf index -t $line; done
srun -p normal bcf merge *vcf.gz -Oz -o Sample.vcf.gz
srun -p normal bcf index -t Sample.vcf.gz
for i in {1..12}; do bcf view -r $i Sample.vcf.gz -Oz -o Chr$i.vcf.gz; done
srun -p normal bcf index -t chr$i.vcf.gz

srun -p normal plink --vcf Sample.vcf.gz --geno 0.1 --maf 0.05  --hwe 0.001 --make-bed --recode vcf-iid --out Sample_qc
for i in {1..12}; do bcf view -r $i Sample_qc_phased.vcf.gz -Oz -o chr$i_qc_phased.vcf.gz; done


### test
# remove '*' marker in REF column of Sample_qc.vcf.gz and name the file as test.vcf.gz
srun -p normal java -jar ~/tools/Beagle5.1/bin/beagle.18May20.d20.jar gt=./test.vcf.gz out=./test_phased
srun -p normal -N 1 -n 32 bcf index -t test_phased.vcf.gz
srun -p normal -N 1 -n 32 bcf view -r 1 test_phased.vcf.gz -Oz -o test_phased_chr1.vcf.gz
# consistance step was canceled because all SNPs are removed for they are absence in the reference. Imputation on un consistanced data directly.
# srun -p normal -N 1 -n 32 java -jar /public/home/cdjykj/impute_test/scripts/conform-gt.24May16.cee.jar ref=/public/home/cdjykj/tools/Beagle5.1/database/chr1.1kg.phase3.v5a.b37.vcf.gz gt=test_phased_chr1.vcf.gz chrom=1 out=test_conformed_chr1
# Reference and target files have no markers in common in interval: 1:72009914-112010151
# srun -p normal -n 32 java -jar /public/home/cdjykj/impute_test/scripts/beagle.18May20.d20.jar ref=/public/home/cdjykj/tools/Beagle5.1/database/chr1.1kg.phase3.v5a.b37.bref3 gt=test_conformed_chr1.vcf.gz out=test_imputed_chr1
# try to do gwas
srun -n 32 plink2 --vcf test_phased.vcf.gz --allow-extra-chr --vcf-half-call 'm' --make-bed --out test
# make ped and map
vcftools --gzvcf test_phased.vcf.gz --plink --out vto
plink --file vto --make-bed --out vto
###


srun -p normal java -jar ~/tools/Beagle5.1/bin/beagle.18May20.d20.jar gt=./Sample_qc.vcf out=./Sample_qc_phased
```

[tassel5](https://bitbucket.org/tasseladmin/tassel-5-source/wiki/UserManual) 

```bash
# sorting the vcf file
run_pipeline.pl -SortGenotypeFilePlugin -inputFile test2.vcf -outputFile test2 -fileType VCF
# vcf->hapmap
run_pipeline.pl -fork1 -vcf test2.vcf  -export test2 -exportType Hapmap -runfork1
# kinship
run_pipeline.pl -importGuess test2.hmp.txt -KinshipPlugin -method Centered_IBS -endPlugin -export test2_kinship.txt -exportType SqrMatrix
# PCA
run_pipeline.pl -fork1 -h test2.hmp.txt -PrincipalComponentsPlugin -covariance true -endPlugin -export test2_pca -runfork1
# MLM
run_pipeline.pl -fork1 -h test2.hmp.txt -FilterSiteBuilderPlugin -siteMinAlleleFreq 0.05 -endPlugin -fork2 -t traits.txt -fork3 -k test2_kinship.txt -combine4 -input1 -input2 -intersect -combine5 -input3 -input4 -mlm -mlmVarCompEst P3D -mlmCompressionLevel Optimum -export test2_mlm -exportType Table
#GLM
run_pipeline.pl -fork1 -h test2.hmp.txt -FilterSiteBuilderPlugin -siteMinAlleleFreq 0.05 -endPlugin -fork2 -t traits.txt -combine5 -input1 -input2 -intersect -FixedEffectLMPlugin -endPlugin -export test2_glm -exportType Table
# plot
python3 plot.py -mht test2_glm1.txt
python3 plot.py -qq test2_glm1.txt
python3 plot.py -pca test2_pca1.txt test2_pca2.txt
```

