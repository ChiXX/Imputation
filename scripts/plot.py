#!/usr/bin/env python3
# coding: utf-8
import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

parser = argparse.ArgumentParser(description='plt.py -<plottype> file')
parser.add_argument('-mht', type=str, help='Manhattan plot')
parser.add_argument('-qq', type=str, help='Q-Q plot')
parser.add_argument('-pca', type=str, nargs='+', help='2 file are required: PCs file Eigenvalue file')
args = parser.parse_args()

def manhattan(data, file):
    df_grouped = data.groupby(('Chr'))
    fig = plt.figure(figsize=(15,6))
    ax = fig.add_subplot(111)
    colors = ['k','grey']
    x_labels = []
    x_labels_pos = []
    for num, (name, group) in enumerate(df_grouped):
        group.plot(kind='scatter', x='ind', y='$-log_{10}(p)$',color=colors[int(name) % len(colors)], ax=ax)
        x_labels.append(name)
        x_labels_pos.append((group['ind'].iloc[-1] - (group['ind'].iloc[-1] - group['ind'].iloc[0])/2))
    ax.set_xticks(x_labels_pos)
    ax.set_xticklabels(x_labels)
    ax.set_xlim([0, len(data)])
    ax.set_ylim([0, 7])
    ax.set_title('Manhattan plot')
    ax.set_xlabel('Chromosome')
    plt.savefig('.'.join(file.split('.')[:-1])+'_mht.png', format='png')

def qqplot(data, file):
    fig, ax = plt.subplots(nrows=1, ncols=1, figsize = (12,12))
    stats.probplot(data['p'], dist='norm', plot=plt)
    ax.set_xlabel("Expected $-log_{10}(p)$")
    ax.set_ylabel("Observed $-log_{10}(p)$")
    ax.set_title('Q-Q plot')
    plt.show()
    plt.savefig('.'.join(file.split('.')[:-1])+'_qq.png', format='png')
    
def pcaplot(data1, data2, file):
    plt.figure(figsize=(20, 8))
    plt.subplot(1, 2, 1)
    plt.scatter(data1['PC1'], data1['PC2'])
    for i in range(len(data1.Taxa)):
        plt.annotate(data1.Taxa[i], xy = (data1.PC1[i], data1.PC2[i]), xytext = (data1.PC1[i]+0.1, data1.PC2[i]+0.1), alpha=0.8)
    plt.title("PCA")
    plt.xlabel('PC1:%.2f'%data2[0])
    plt.ylabel('PC2:%.2f'%data2[1])

    plt.subplot(1, 2, 2)
    plt.scatter(data1['PC3'], data1['PC4'])
    for i in range(len(data1.Taxa)):
        plt.annotate(data1.Taxa[i], xy = (data1.PC3[i], data1.PC4[i]), xytext = (data1.PC3[i]+0.1, data1.PC4[i]+0.1), alpha=0.8)
    plt.title("PCA")
    plt.xlabel('PC3:%.2f'%data2[2])
    plt.ylabel('PC4:%.2f'%data2[3])

    plt.tight_layout()
    plt.savefig('.'.join(file.split('.')[:-1])+'_pca.png', format='png')

if args.mht != None:
    data = pd.read_csv(args.mht, sep='\t')[['Chr', 'Pos', 'p']].dropna()
    data['$-log_{10}(p)$'] = -np.log10(data['p'])
    data['ind'] = range(len(data))
    manhattan(data, args.mht)
if args.qq != None:
    data = pd.read_csv(args.qq, sep='\t')[['Chr', 'Pos', 'p']].dropna()
    qqplot(data,args.qq)
if args.pca != None:
    data1 = pd.read_csv(args.pca[0], sep='\t', header=2)
    data2 = list(pd.read_csv(args.pca[1], sep='\t')['proportion of total'])
    pcaplot(data1, data2, args.pca[0])
if args == None:
    print('Use -h for more information')