## Imputation

### 1. vcf file converting

Genetype file should in [vcf](http://samtools.github.io/hts-specs/VCFv4.2.pdf) format, using ```./scripts/2vcf.py```to make this.

```python
python 2vcf.py -h
```

*notes:* 

* ALT could be same as REF
* locas could duplicate

### 2. phasing

using beagle

```bash
java -jar ../scripts/beagle.18May20.d20.jar gt=../data/genotype.vcf out=../data/genotype.gt
```

### 3. preparing

Split the phased genotype file by chromosome with ```./scripts/merge_and_split.py```

```bash
python3 ./scripts/merge_and_split.py -op s -i ./data/genotype.gt.vcf.gz -o ./data/vcfs
```

Download the [reference](http://bochet.gcc.biostat.washington.edu/beagle/1000_Genomes_phase3_v5a/) and adjust the target genomic position consistent with the reference with [conform-gt](http://faculty.washington.edu/browning/conform-gt.html). The [population](http://bochet.gcc.biostat.washington.edu/beagle/1000_Genomes_phase3_v5a/sample_info/integrated_call_samples_v3.20130502.ALL.panel) infomation of reference genotype is listed below:

|  super_pop  | abbreviation |
| :---------: | :----------: |
| East Asian  |     EAS      |
| South Asian |     SAS      |
|   African   |     AFR      |
|  European   |     EUR      |
|  American   |     AMR      |

conform-gt usage:

```bash
ls /data/share/1KG/b37/b37.bref3 | cut -d '.' -f1 | while read line; do java -jar scripts/conform-gt.24May16.cee.jar ref=/data/share/1KG/b37/b37.vcf/chr${line:3}.1kg.phase3.v5a.b37.vcf.gz gt=./data/vcfs/chr${line:3}.vcf.gz chrom=${line:3} out=./data/vcfs/conform.chr${line:3}; done
```

Conversion between vcf and bref3 can be achived with [bref3](http://faculty.washington.edu/browning/beagle/bref3.18May20.d20.jar) and [unbref3](http://faculty.washington.edu/browning/beagle/unbref3.18May20.d20.jar) as below:

```bash
ls * | cut -d '.' -f 1-5 | while read line; do java -jar ~/Imputation/scripts/unbref3.18May20.d20.jar $line.bref3 > ../b37.vcf/$line.vcf; done
```

### 4. Imputation 

Impute with Beagle5.1

```bash
ls ./data/vcfs/conform.* | cut -d '.' -f3 | uniq | while read line; do java -jar ./scripts/beagle.18May20.d20.jar ref=/data/share/1KG/b37/b37.bref3/$line.1kg.phase3.v5a.b37.bref3 gt=./data/vcfs/conform.$line.vcf.gz out=./data/imputed/$line; done
```

Merge file

```bash
python3 ./scripts/merge_and_split.py -op m -i ./data/imputed -o ./data/genotype.imputed
```











