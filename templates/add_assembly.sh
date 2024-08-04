#!/bin/bash
# Created by Michal Bukowski (michal.bukowski@tuta.io, m.bukowski@uj.edu.pl)
# under GPL-3.0 license

# A template for a Nextflow pipeline. It adds genome assembly accession version
# column to translated BLAST results.
# Variables:
# cols     : reported BLAST results columns with the assembly column name added
#            in the first position
# assembly : assembly accession version number of an analysed genome
# resFile  : BLAST results file (expected format: TSV)
# outFile  : the results file with the assembly column added (output format: TSV)

echo "${cols}" > ${outFile}
while read line; do
    echo "${assembly}\t\${line}" >> ${outFile}
done < ${resFile}

