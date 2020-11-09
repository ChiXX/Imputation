## Imputation

### 1. vcf file converting

genetype file should in vcf format, using ```./scripts/2vcf.py```to achive this.

```python

python 2vcf.py -h

```

*notes:* AlT could be same as REF, locas could duplicate

### 2. phasing

using beagle

```bash

java -jar ../scripts/beagle.18May20.d20.jar gt=../data/genotype.vcf out=../data/genotype.gt

```