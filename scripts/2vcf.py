#!/usr/bin/env python
# coding: utf-8
import argparse
import pandas as pd
import numpy as np

parser = argparse.ArgumentParser(description="run like: python ./scripts/2vcf.py -i ./data/genotype.txt -o ./data/genotype.vcf -n 10\nrequired: python3, pandas, numpy")
parser.add_argument('-i', type=str, help='input file path',required=True)
parser.add_argument('-r', type=str, help='reference file path',required=True)
parser.add_argument('-o', type=str, help='output file path',required=True)
parser.add_argument('-n', type=int, help='number of samples',required=True)
args = parser.parse_args()

gt_path = args.i
ref_path = args.r
out_path = args.o
sample = args.n

header = 0
with open(gt_path) as fi, open(out_path, 'w') as fo:
    for l in fi:
        if l.startswith('##'):
            fo.write(l)
            header+=1
        else:
            break


target = pd.read_csv(gt_path, sep='\t', header=header).sort_values(by=['#CHROM'])
samples = target.columns[-sample:]
target['IlluminaName'] = target.apply(lambda x: x['INFO'].split(';')[0], axis=1)

ref = pd.read_csv(ref_path, sep='\t').drop(['IlluminaID', 'CHROM_POS', 'ID', 'Top_Strand', 'REF','match.position', 'mismatch', 'source'], axis=1)
ref.columns = ['IlluminaName', '#CHROM', 'POS', 'ALT']

target = pd.merge(target, ref, on = ['#CHROM', 'POS', 'IlluminaName'])
target.drop_duplicates(subset=['#CHROM','POS','REF','ALT'],keep='first',inplace=True)
target['ALT'] = target.apply(lambda x: '.' if x['ALT'] == x['REF'] else x['ALT'], axis=1)

def incode(ref, alt, sp):
    r, l = '.', '.'
    if len(ref) > len(alt):
        I, D = '0', '1'
    else:
        I, D = '1', '0'
    if sp[0] == '-': r = '.'
    if sp[1] == '-': l = '.'
    if sp[0] == 'D': r = D
    if sp[1] == 'D': l = D
    if sp[0] == 'I': r = I
    if sp[1] == 'I': l = I
    if sp[0] == ref[0]: r = '0'
    if sp[1] == ref[0]: l = '0'
    if sp[0] == alt[0]: r = '1'
    if sp[1] == alt[0]: l = '1'
    return r+'/'+l

target['FORMAT'] = 'GT'
target['QUAL'] = '.'
target['FILTER'] = '.'
for sp in samples:
    target[sp] = target.apply(lambda x: incode(x['REF'], x['ALT'], x[sp]), axis=1)
    
target = target[['#CHROM', 'POS', 'ID', 'REF', 'ALT', 'QUAL', 'FILTER', 'INFO', 'FORMAT']+list(samples)]
for sp in samples:
    target=target[target[sp] != '/']
target.sort_values(by=['#CHROM', 'POS']).to_csv(out_path, sep='\t', mode='a', index=False)
print('output to ', out_path)