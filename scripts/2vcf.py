#!/usr/bin/env python
# coding: utf-8
import os
import pandas as pd
import numpy as np
import gc


ref_path = '/data/1KG/hs37d5.fa'
tg_path = '../data/target'
refs = '../data/refs'

# split the reference data by chromosome
def split_ref(ref_path, refs):
    with open(ref_path) as f:
        writed = False
        for l in f:
            if l.startswith('>'):
                if writed:
                    o.close()
                o = open(refs+'/'+l.rstrip()[1:].split(' ')[0]+'.fa', 'w')
                o.write(l)
                writed = False
            else:
                writed = True
                o.write(l.rstrip())
        o.close()
    del writed, f, l, o
    gc.collect()

if len(os.listdir(refs)) == 0:
    split_ref(ref_path, refs)

target = pd.read_csv(tg_path+'/'+'028-1111-2264.txt', sep='\t', header=12).sort_values(by=['#CHROM'])
chrom = list(target['#CHROM'].unique())


target2 = []
for i in chrom:
    tar = target[target['#CHROM'] == i]
    dic ={}
    with open(refs+'/'+i+'.fa') as f:
        for j, k in enumerate(f.readlines()[1]):
            dic[j+1] = k
    tar['REF'] = tar.apply(lambda x: dic[int(x['POS'])], axis=1)
    target2.append(tar)
    del dic, tar
    gc.collect()


target2 = pd.concat(target2, axis=0)


target2['FORMAT'] = 'GT'
target2['QUAL'] = '.'
target2['FILTER'] = '.'
target2['ALT'] = target3.apply(lambda x: '.' if x['REF']==x['028-1111-2264'][0]==x['028-1111-2264'][1] else
                                         x['028-1111-2264'][0] if x['REF']!=x['028-1111-2264'][0] and x['REF']==x['028-1111-2264'][1] else
                                         x['028-1111-2264'][1] if x['REF']==x['028-1111-2264'][0] and x['REF']!=x['028-1111-2264'][1] else
                                         x['028-1111-2264'][0]+','+x['028-1111-2264'][1] if x['028-1111-2264'][0]!=x['028-1111-2264'][1] else 
                                         x['028-1111-2264'][0] if x['028-1111-2264'][0]==x['028-1111-2264'][1] else np.nan,axis=1)
target2['Sample1'] = target3.apply(lambda x: '0/0' if x['ALT']=='.' else
                                           '1/1' if x['ALT'] == x['028-1111-2264'][0] == x['028-1111-2264'][1] else
                                           '0/1' if x['ALT'] == x['028-1111-2264'][1] else
                                           '1/0' if x['ALT'] == x['028-1111-2264'][0] else './.',axis=1)
target2.drop(['028-1111-2264'], axis=1, inplace=True)
target2 = target3[['#CHROM', 'POS', 'ID', 'REF',  'ALT', 'QUAL',  'FILTER', 'INFO', 'FORMAT', 'Sample1']].sort_values(by=['#CHROM', 'POS'])

target2.to_csv(tg_path+'/'+'028-1111-2264.vcf', sep='\t', index=False)
