#!/usr/bin/env nextflow
/* Created by Michal Bukowski (michal.bukowski@tuta.io, m.bukowski@uj.edu.pl)
   under GPL-3.0 license. For detail see the following publication:
   
   Bukowski M, Banasik M, Chlebicka K, Bednarczyk K, Żądło T, Dubin G, Władyka B.
   Analysis of co-occurrence of toxin-antitoxin systems and antibiotic resistance
   determinants in Staphylococcus spp. [awaiting publication]
   
   Nextflow pipeline for automated translated BLAST searches in genomic sequences.
   
   This pipeline utilises CARD data (located in the input directory):
   
   Alcock BP, Huynh W, Chalil R, Smith KW, Raphenya AR, Wlodarski MA,
   Edalatmand A, Petkau A, Syed SA, Tsang KK, Baker SJ. CARD 2023:
   expanded curation, support for machine learning, and resistome prediction
   at the Comprehensive Antibiotic Resistance Database. Nucleic acids research.
   2023 Jan 6;51(D1):D690-9.
   
   It is highly recommended to obtain the current data set from card.mcmaster.ca
   (Download/Download CARD Data). The pipeline utilises the protein homology
   model sequences.
   
   In envs/ directory YML files describe conda environments used by the pipeline.
   If you want to install the latest versions of the packages, remove version
   designations from all YML files (=X.X.*).
   
   Miniconda/Anaconda installation is a prerequisite. The default environment that
   must be created prior running the pipeplie is described in nextflow.yml.
   It utilises nexflow package, ver. 23.10.0. Run the following commands from
   the pipeline directory to create and activate the environment:
   
   conda env create -f envs/tblastn-nextflow.yml
   conda activate tblastn-nextflow
   
   The processes ustilises scripts located in templates/ directory. To start
   the pipeline run the command from the pipeline directory:
   
   nextflow main.nf
   
   Detailed comments on what each process do and how are provided at the end of
   this file in the workflow{} block as well as in comments in template files.
   
   Values for technical parameters are defined in the nextflow.config file.
*/

process tblastnGenomes{
    conda      'envs/tblastn-blast.yml'
    publishDir 'output/tblastn', mode: 'link'
    
    input:
        each path(queryFile)
        each path(genFile)
        
    exec:
        fmt     = params.blastfmt
        cols    = params.blastcols
        evalue  = params.blasteval
        gencode = params.blastcode
        (_, assembly) = (genFile.getName() =~ /^([A-Z]+_[0-9]+\.[0-9]+)/)[0]
        (_, query)    = (queryFile.getName() =~ /^([^\.]+)\.faa/)[0]
        outFile  = "${assembly}_${query}_tblastn.tsv"
        
    output:
        tuple val(assembly), val(query), val(cols), path(outFile)
    
    script:
        template 'blast.sh'
}

process addAssembly {
    publishDir 'output/tblastn_asm', mode: 'link'
    
    input:
        tuple val(assembly), val(query), val(cols), path(resFile)
    
    exec:
        cols = 'assembly\t' + cols.replace(' ', '\t')
        outFile = "${assembly}_${query}_tblastn_asm.tsv"
    
    output:
        path(outFile)
        
    script:
        template 'add_assembly.sh'
}

process filterResults {
    conda      'envs/tblastn-data.yml'
    publishDir 'output/tblastn_filtered', mode: 'link'
    
    input:
        path(resFile)
        
    exec:
        outFile = "${resFile.baseName}_filtered.tsv"
        
    output:
        path outFile
    
    script:
        template 'filter.py'
}

workflow {
    /* INPUT FILES
       
       The pipeline expects the following input files:
       queries  - a directory with protein FASTA files, each containing
                  a set of sequences to be searched for corresponding coding
                  sequences in analysed genomes. The file names must follow the
                  pattern: <setName>.faa
       genomes  - a directory (here local directory fna) with genomic sequences,
                  genomic sequence(s) for each genomes are in a gzipped FASTA
                  file with the following NCBI GenBank name pattern:
                  <assemblyAccessionVersion>_genomic.fna.gz
                  
    */
    queries = Channel.fromPath(params.queryDir + '/*.faa')
    genomes = Channel.fromPath(params.genDir + '/*_genomic.fna.gz')
    
    /* The pipeline is very simple:
       STAGE 1: tblastnGenomes searches for sequences in analysed genomes that
                code for similar protein sequences to those from query sets.
       STAGE 2: addAssembly simply adds to BLAST search results a column with
                assembly accession version of the analysed genome, useful
                for downstream analyses (it links a match to a given genome).
       STAGE 3: filterRes filters the results in order to obtain a set of
                the best non-overlapping matches. At the end results for all
                genomes are merged into one file (output/tblastn_merged.tsv).
       See comments in the template files for more details.
    */
    tblastnGenomes(queries, genomes)
    | addAssembly
    | filterResults
    | collectFile(
        name: 'tblastn_merged.tsv',
        storeDir: 'output',
        keepHeader: true
    )
}

