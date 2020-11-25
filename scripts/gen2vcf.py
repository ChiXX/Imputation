#!/usr/bin/env python
# coding: utf-8
import argparse

parser = argparse.ArgumentParser(description="convert impute2 output file to VCF format")
parser.add_argument('-i', type=str, help='input file',required=True)
parser.add_argument('-s', type=str, help='.sample file',required=True)
parser.add_argument('-o', type=str, help='output file',required=True)
args = parser.parse_args()

ipt = args.i
smp = args.s
opt = args.o

header = '##fileformat=VCFv4.2' + '\n' + '##FORMAT=<ID=GP,Type=Float,Description="Genotype call probabilities">'
IDs = '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT'
with open(smp) as f:
    for i,l in enumerate(f):
        if i >= 2:
            IDs += ('\t'+l.split(' ')[0])
            
with open(ipt) as fi, open(opt, 'w') as fo:
    fo.write(header +'\n' +IDs +'\n')
    for l in fi:
        info1 = l.rstrip().split(' ')
        info2 = [info1[1].split(':')[0], info1[2], '.', info1[3], info1[4], '.', '.', '.', 'GP'] + [','.join(info1[i:i+3]) for i in range(5, len(IDs)-9, 3)]
        fo.write('\t'.join(info2))    