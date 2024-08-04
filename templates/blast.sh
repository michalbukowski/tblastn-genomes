#!/bin/bash
# Created by Michal Bukowski (michal.bukowski@tuta.io, m.bukowski@uj.edu.pl)
# under GPL-3.0 license

# A template for a Nextflow pipeline. It runs a translated BLAST search.
# Variables:
# gencode   : the translation table for the translated BLAST search
# evalue    : E-value reporting threshold
# fmt       : BLAST results format number (required format no. 6, TSV)
# cols      : BLAST results columns to be reported
# queryFile : protein FASTA file with one set of query sequences
# genFile   : gzipped FASTA file with one genome sequence(s) to be searched
# outFile   : BLAST results output file (output format: TSV)

tblastn -db_gencode  ${gencode}              \
        -evalue      ${evalue}               \
        -outfmt     "${fmt} ${cols}"         \
        -query       ${queryFile}            \
        -subject     <(gunzip -c ${genFile}) \
        -out         ${outFile}

