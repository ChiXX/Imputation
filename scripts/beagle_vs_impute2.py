#!/usr/bin/env python
# coding: utf-8
import argparse
import pandas as pd
import numpy as np
import gzip

bg_path = './data/comp/chr10.bg.vcf.gz'
ip2_path = './data/comp/chr10.ip2.vcf.gz'
header1 = 0
header2 = 0

with gzip.open(bg_path) as f1, gzip.open(ip2_path) as f2:
    for l in f1:
        if l.startswith(b'##'):
            header1+=1
        else:
            break
    for l in f2:
        if l.startswith(b'##'):
            header2+=1
        else:
            break

beagle = pd.read_csv(bg_path, sep='\t', header=header1, compression='gzip').sort_values(by=['POS'])
beagle = beagle[beagle['POS']<18000000][['POS','REF','ALT']+['CHIA-'+str(i) for i in range(1, 11)]]
beagle[['POS','REF','ALT']+['CHIA-'+str(i) for i in range(1, 11)]]
impute2 = pd.read_csv(ip2_path, sep='\t', header=header2, compression='gzip').sort_values(by=['POS'])
impute2 = impute2[['POS','REF','ALT']+['sample_'+str(i) for i in range(0, 10)]]
impute2.columns = ['POS', 'REF', 'ALT', 'sample_3', 'sample_4', 'sample_6', 'sample_8', 'sample_10', 'sample_9', 'sample_2', 'sample_1', 'sample_7', 'sample_5']

def beagle_decode(ref, alt, sample):
    locus = sample.split(':')[0].split('|')
    if locus[0] == locus[1]:
        if locus[0] == '0':
            return 0
        elif locus[0] == '1':
            return 2
        else:
            return np.nan
    else:
        return 1

def ipt2_decode(sample):
    locus = sample.split(',')
    if float(max(locus)) < 0.8:
        return np.nan
    else:
        return locus.index(max(locus))

for sp in ['CHIA-'+str(i) for i in range(1, 11)]:
    beagle[sp] = beagle.apply(lambda x: beagle_decode(x['REF'], x['ALT'], x[sp]), axis=1)
for sp in ['sample_'+str(i) for i in range(1, 11)]:
    impute2[sp] = impute2.apply(lambda x: ipt2_decode(x[sp]), axis=1)

result = pd.merge(beagle, impute2.dropna(axis=0), on=['POS','REF','ALT'])

# markdown table form
print('|Sample|Similarity|')
print('|:--:|:--:|')
for i in range(1,11):
    err = result[result['CHIA-'+str(i)]!=result['sample_'+str(i)]].shape[0]/result.shape[0]
    print(f'|CHIA-{i}|{1-err}|')