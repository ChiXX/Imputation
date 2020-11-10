#!/usr/bin/env python
# coding: utf-8
import argparse
from argparse import RawTextHelpFormatter
import pandas as pd
import os
import gzip

parser = argparse.ArgumentParser(description= "split or merge vcf file(s) by assigning the op parameter, file should in gz format\n"
                               "run like:\npython3 ../scripts/merge_and_split.py -op s -i genotype.gt.vcf.gz -o ./vcfs\n"
                               "python3 ../scripts/merge_and_split.py -op m -i ./vcfs -o ./vcfs/merge.vcf\n"
                               "required: python3, pandas", formatter_class=RawTextHelpFormatter)
parser.add_argument('-op', choices=['s', 'm'], type=str, help='m: merge\ts: split\n',required=True)
parser.add_argument('-i', type=str, help='input file or folder',required=True)
parser.add_argument('-o', type=str, help='output folder or file',required=True)
args = parser.parse_args()


def merge():
    header = 0
    targets = [f for f in os.listdir(args.i) if 'vcf.gz' in f]
    with gzip.open(args.i+'/'+targets[0], 'rb') as fi, gzip.open(args.o+'.gz', 'wb') as fo:
        for l in fi:
            if l.startswith(b'#'):
                fo.write(l)
                header+=1
            else:
                break
    for f in targets:
        pd.read_csv(args.i+'/'+f, sep='\t',header=header-1, compression='gzip').to_csv(args.o+'.gz', sep='\t', mode='a', header=None, index=False, compression='gzip')

    
def split():
    header = b''
    with gzip.open(args.i, 'rb') as fi:
        for l in fi:
            if l.startswith(b'##'):
                header+=l
            else:
                break
    vcf = pd.read_csv(args.i, sep='\t', header=len(header.split(b'\n'))-1, compression='gzip')
    vcf[["#CHROM"]] = vcf[["#CHROM"]].astype(str)
    chrs = list(vcf['#CHROM'].drop_duplicates(keep='first'))
    for c in chrs:
        with gzip.open(args.o+'/chr'+c+'.vcf.gz', 'wb') as fo:
            fo.write(header)
        vcf[vcf['#CHROM'] == c].to_csv(args.o+'/chr'+c+'.vcf.gz', sep='\t',  mode='a', index=False, compression='gzip')


if args.op == 'm':
    merge()
if args.op == 's':
    split()