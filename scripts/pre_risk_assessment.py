#!/usr/bin/env python
# coding: utf-8

import pandas as pd
import numpy as np
import os

vcf_path = '/public/home/cdjykj/impute_test/data/imputed/all.gen'
site_info = '/public/home/cdjykj/impute_test/site_info/'
sex_dir = '/public/home/cdjykj/impute_test/data/plink.sexcheck'
dirs = '/public/home/cdjykj/impute_test/data/sample_sites' # output results

sites = [s for f in os.listdir(site_info) for s in pd.read_csv(site_info+f, encoding='gb18030')['site'].dropna().drop_duplicates().tolist()]

with open(vcf_path) as f, open('tmp', 'w') as t:
    for l in f:
        if l.split(' ')[1].startswith('rs'):
            if l.split(' ')[1].split(':')[0] in sites:
                t.write(l)


target = pd.read_csv('tmp', sep='\s+', header=None)
target['ID'] = target.apply(lambda x: x[1].split(':')[0] if 'rs' in x[1] else np.nan, axis=1)
target.dropna(inplace=True)
target = target[target.ID.apply(lambda x: True if x in sites else False)]
if len(target.ID) != len(sites):
    missing = []
    for t in sites:
        if t not in target.ID:
            missing.append(t)
    print(missing)
    
sex_info = pd.read_csv(sex_dir, sep='\s+')
sex_info['Sex'] = sex_info.apply(lambda x: 'M' if x.F > 0.8 else 'F' if x.F < 0.2 else 'E', axis=1)
sex_dict = sex_info[['FID', 'Sex']].set_index('FID').to_dict()['Sex']

def conversion(ref, alt, p1, p2, p3):
    p = [p1, p2, p3]
    tp = p.index(max(p))
    if tp == 0:
        return ref+ref
    if tp == 1:
        return ref+alt
    if tp == 2:
        return alt+alt

i = 1
for s in sex_info['FID']:
    target[s] = target.apply(lambda x: conversion(x[3], x[4], x[3*i+2],x[3*i+3], x[3*i+4]), axis=1)
    i += 1
    
    
if not os.path.exists(dirs):
    os.mkdir(dirs)
for k in sex_dict:
    if not os.path.exists(dirs+'/'+k):
        os.mkdir(dirs+'/'+k)
    target[['ID', k]].to_csv(dirs+'/'+k+'/'+k+'.'+sex_dict[k], sep='\t', header=False, index=False)    

os.remove('tmp')





