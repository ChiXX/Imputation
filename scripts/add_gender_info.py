#!/usr/bin/env python
# coding: utf-8
import argparse
import os

parser = argparse.ArgumentParser(description="add gender information to .sample file")
parser.add_argument('-g', type=str, help='genderinfo file',required=True)
parser.add_argument('-s', type=str, help='sample file',required=True)
args = parser.parse_args()

genderinfo = args.g
sample = args.s

with open(genderinfo) as f1, open(sample) as f2, open(sample+'+', 'w') as f3:
    gender = {l.rstrip().split(',')[3]:l.split(',')[2] for l in f1}
    for i, l in enumerate(f2):
        if i == 0:
            f3.write(l.rstrip()+' sex\n')
        elif i == 1:
            f3.write(l.rstrip()+' D\n')
        else:
            info = lambda l, gender: '1\n' if gender[l.split(' ')[0]] == 'Male' else '2\n' 
            f3.write(l.rstrip()+' '+info(l,gender))
            
os.remove(sample)
os.rename(sample+'+', sample)
