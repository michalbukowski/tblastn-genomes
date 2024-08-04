#!/usr/bin/env python3
# Created by Michal Bukowski (michal.bukowski@tuta.io, m.bukowski@uj.edu.pl)
# under GPL-3.0 license

# A template for a Nextflow pipeline. It filters a translated BLAST search
# results with respect to the query coverage and sequence similarity as well as
# removes overlapping matches by preserving the best one in a given location
# within genomic sequence(s) of one genome. The results contain matches of
# a set of protein query sequences to genomic sequence(s) of one genome.
# Variables:
# resFile : BLAST results output file for one set of queries and one genome
#           (required format: TSV)
# outFile : output filtered BLAST results (output format: TSV)

import argparse
import pandas as pd

res_df = pd.read_csv('${resFile}', sep='\\t')

if res_df.shape[0] == 0:
    res_df['strand qcovs'.split()] = None
    res_df.to_csv('${outFile}', index=False, sep='\\t')
    return

res_df['qcovs'] = (( (res_df['qstart'] - res_df['qend']).abs() + 1 )
                   / res_df['qlen']).round(2)
res_df['ppos'] = (res_df['ppos'] / 100).round(2)
res_df = res_df[
    (res_df['qcovs'] >= 0.9) &
    (res_df['ppos']  >= 0.8)
].copy()
res_df = res_df[ ~res_df['sseq'].str.contains('\\*') ].copy()

if res_df.shape[0] == 0:
    res_df['strand'] = None
    res_df.to_csv('${outFile}', index=False, sep='\\t')
    return

minus = res_df['sstart'] > res_df['send']
res_df['strand'] = 1
res_df.loc[minus, 'strand'] = -1
res_df.loc[minus, 'sstart send'.split()] = res_df.loc[minus, 'send sstart'.split()].to_numpy()
res_df.sort_values('sseqid sstart send'.split(), inplace=True)

tbd = set()
for _, sub_df in res_df.groupby('sseqid strand'.split()):
    if sub_df.shape[0] == 1:
        continue
    for ia in range(sub_df.shape[0]-1):
        row_a = sub_df.iloc[ia]
        for ib in range(ia+1, sub_df.shape[0]):
            row_b = sub_df.iloc[ib]
            if row_a.name in tbd or row_b.name in tbd:
                continue
            elif row_b['sstart'] >  row_a['send']:
                break
            elif row_b['ppos']   >= row_a['ppos']:
                tbd.add(row_a.name)
            else:
                tbd.add(row_b.name)
res_df.drop(tbd, inplace=True)

if res_df.shape[0] == 0:
    res_df.to_csv('${outFile}', index=False, sep='\\t')
    return

minus = res_df['strand'] == -1
res_df.loc[minus, 'sstart send'.split()] = res_df.loc[minus, 'send sstart'.split()].to_numpy()
res_df.drop('strand sseq'.split(), axis=1, inplace=True)

res_df.to_csv('${outFile}', index=False, sep='\\t')

