## Pipeline for automated translated BLAST searches in genomic sequences (tblastn-genomes)

Nextflow pipeline for automated translated BLAST searches in genomic sequences. For a broader context, see the following publication:

Bukowski M, Banasik M, Chlebicka K, Bednarczyk K, Bonar E, Sokołowska D, Żądło T, Dubin G, Władyka B. (2025) _Analysis of co-occurrence of type II toxin–antitoxin systems and antibiotic resistance determinants in Staphylococcus aureus_. mSystems 0:e00957-24.
https://doi.org/10.1128/msystems.00957-24

This pipeline utilises CARD data (located in the input directory):

Alcock BP, Huynh W, Chalil R, Smith KW, Raphenya AR, Wlodarski MA, Edalatmand A, Petkau A, Syed SA, Tsang KK, Baker SJ. _CARD 2023: expanded curation, support for machine learning, and resistome prediction at the Comprehensive Antibiotic Resistance Database_. Nucleic acids research. 2023 Jan 6;51(D1):D690-9.

It is highly recommended to obtain the current data set from [card.mcmaster.ca](https://card.mcmaster.ca) (Download/Download CARD Data). The pipeline utilises the protein homology model sequences.

Detailed comments on what and how each process do are provided in the `main.nf` file as well as in comments in the template files.

Values for technical parameters are defined in the `nextflow.config` file.

### 1. Environment
In envs/ directory YML files describe conda environments used by the pipeline. If you want to install the latest versions of the packages, remove version designations from all YML files (`=X.X.*`). The repository has been tested on `Ubuntu 22.04` using `conda 24.11`.

`Miniconda`/`Anaconda` installation is a prerequisite. The `tblastn-nextflow` environment described in the `tblastn-nextflow.yml` file must be created prior running the pipepline. It utilises `nexflow 23.10` package. Run the following command from the pipeline directory to create the environment:
```
conda env create -f envs/tblastn-nextflow.yml
```

### 3. Directory structure and pipeline files
```
tblastn-genomes/
├── envs/
│   ├── tblastn-nextflow.yml
│   ├── tblastn-blast.yml
│   └── tblastn-data.yml
├── input/
│   ├── antitoxins.faa
│   ├── toxins.faa
│   └── card.faa
├── templates/
│   └── filter.py
├── fna/
├── work/
├── output/
├── nextflow.config
└── main.nf
```

In the working directory you can find the `main.nf` file that describes the pipeline next to `nextflow.config` file describing the pipeline technical configuration. The `envs/` directory contains YML files describing conda environments. In the `input/` directory sets of protein query sequences are located. In the `fna/` directory genomic sequences of analysed genomes are supposed to be located. The location of last two directories can be changed in the `nextflow.config` file. Template scripts are in `template/`. Directories `work/` and `output/` will be created automatically once the pipeline is run. The latter will contain final output from each stage of the analysis.

### 4. Pipeline architecture
The pipeline expects the following input files:
1. `queries` - a directory with protein FASTA files, each containing a set of sequences to be searched for corresponding coding sequences in analysed genomes. The file names must follow the pattern: <setName>.faa
1. `genomes` - a directory (here local directory fna) with genomic sequences, genomic sequence(s) for each genomes are in a gzipped FASTA file with the following NCBI GenBank name pattern: <assemblyAccessionVersion>_genomic.fna.gz

The pipeline encompasses the following stages:
1. `tblastnGenomes` searches for sequences in analysed genomes that code for similar protein sequences to those from query sets.
1. `addAssembly` simply adds to BLAST search results a column with assembly accession version of the analysed genome, useful for downstream analyses (it links a match to a given genome).
1. `filterRes` filters the results in order to obtain a set of the best non-overlapping matches. At the end results for all genomes are merged into one file (`output/tblastn_merged.tsv`).

See comments in the template files for more details.

### 5. Running the pipeline
To start the pipeline activate the `tblastn-nextflow` environment and run Nextflow from the pipeline directory:
```
conda activate tblastn-nextflow
nextflow main.nf
```
