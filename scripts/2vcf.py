#!/usr/bin/env python
# coding: utf-8
import argparse
import pandas as pd
import numpy as np

parser = argparse.ArgumentParser(description="run like: python 2vcf.py -i ../data/genotype.txt -o ../data/genotype.vcf -n 2"+'\n'+
                               "required: python3, pandas, numpy")
parser.add_argument('-i', type=str, help='input file path',required=True)
parser.add_argument('-o', type=str, help='output file path',required=True)
parser.add_argument('-n', type=int, help='number of samples',required=True)
args = parser.parse_args()

gt_path = args.i
out_path = args.o
sample = args.n
header = 0

with open(gt_path) as fi, open(out_path, 'w') as fo:
    for l in fi:
        if l.startswith('##'):
            fo.write(l)
            header += 1
        else:
            break


target = pd.read_csv(gt_path, sep='\t', header=header)
samples = list(target.columns[-sample:])

def alt(ref, nns):
    if '-'in nns:
        nns.remove('-')
    if ref in nns:
        if len(nns) == 1: 
            return '.'
        else:
            nns.remove(ref)
            return ','.join(nns)
    else:
        if len(nns) == 0: 
            return np.nan
        else:
            return ','.join(nns)
    
def incode(ref, alt, sp):
    if alt is np.nan: return np.nan
    r, l = '', ''
    for i, v in enumerate([ref]+alt.split(',')):
        if sp[0] == v: r = str(i)
        if sp[1] == v: l = str(i)
    if len(r+l) != 2: return np.nan
    return r+'|'+l

target['FORMAT'] = 'GT'
target['QUAL'] = '.'
target['FILTER'] = '.'
target['ALT'] = target.apply(lambda x: alt(x['REF'], list(np.unique(list(''.join(x[samples]))))),axis=1)
for sp in samples:
    target[sp] = target.apply(lambda x: incode(x['REF'], x['ALT'], x[sp]), axis=1)
target = target[['#CHROM', 'POS', 'ID', 'REF', 'ALT', 'QUAL',  'FILTER', 'INFO', 'FORMAT']+samples]

target.sort_values(by=['#CHROM', 'POS']).to_csv(out_path, sep='\t', mode='a', index=False)
print('output to ', out_path)