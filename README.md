# QuaCk

## Introduction

**QuaCk** is a quality control pipeline built to handle both PacBio and ONT longreads as well as Illumina short read data. This pipeline has also been modified to perform quality control on data with pre existing assemblies.

## Table of Contents
- [Quick Start](#quick-start)
    - [Samplesheet.csv input](#samplesheet-csv)
    - [Params.yaml input](#params-yaml)
- [Assembly Options](#assembly-options)
- [Long Read Options](#long-read-options)
- [Short Read Options](#short-read-options)
- [Credits](#credits)
- [Citations](#citations)


## Quick Start

### Running the Pipeline

First pull the pipeline from gitlab

`nextflow pull PlantGenomicsLab/qc-nf -hub gitlab -r main`

This current version allows you to run with either a samplesheet csv or the params.yaml file as your input

#### The typical command to run is as follows:
- To Run with the samplesheet.csv

`nextflow run PlantGenomicsLab/qc-nf -profile <run type profile>,<institutional config> --input samplesheet.csv --input_type 'csv'`

- To run with the params yaml file

`nextflow run PlantGenomicsLab/qc-nf -profile <institutional config> -params-file --input_type 'yaml'`

### Command Line

To specify which one you want to use, always include `--input_type` into the command line followed by `'csv'` or `'yaml'`

---
### Samplesheet CSV

#### Samplesheet example

```
sample,fastq_1,fastq_2,fasta,single_end,read_type
chr3_gibbon,/core/projects/EBP/conservation/gen_assembly_pipeline/hoolock/hoolock_chrm_3/chr3_pb.fastq.gz,,/core/projects/EBP/conservation/gen_assembly_pipeline/hoolock/hoolock_chrm_3/chrm_3_samplesheet_test/02_assembly/long_read/hifiasm/hifiasm_gibbon.fasta,FALSE,pb
```
### Columns: 

`sample` : sample name

`fastq_1` : path to first fastq file

`fastq_2` : path to second fastq file (optional)

`fasta` : path to fasta file (if assembled)

`singled_end` : set to false is paired end

`read_type` : ont, pb, or ill

### Config Profiles

When running with a samplesheet.csv input, a profile needs to be made in the `/conf/` directory containing the necessary modified parameters for your run.

#### Profile example:

```   
    params {
    
    config_profile_name        = 'Busco'
    config_profile_description = 'Minimal test for BUSCO on assembled reads'

    // required workflow inputs

    input = '/core/projects/EBP/conservation/gen_assembly_pipeline/quality_check_pipeline/samplesheet.csv'
    outdir = 'test'
    manual_genome_size = '866000000'
    busco_lineage = 'primates_odb10'
    busco = true
    existing_assembly = true

    email  = ''

    // Limit resources so that this can run on GitHub Actions
    max_cpus   = 4
    max_memory = '5.GB'
    max_time   = '1.h'
    
}
```

---
### Params YAML
> When running with yaml, it is important to note that you can only use one yaml per run
#### Yaml Format Example

```
sample              : "chr3_gibbon" 
genome              : "/core/projects/EBP/conservation/gen_assembly_pipeline/hoolock/hoolock_chrm_3/chrm_3_ont+pb+ill_ehg_output/02_assembly/long_read/flye/flye_chr3_gibbon_pb_T1.trim.fastq.unclassified.fastq.fasta"
ont                 :  "/core/projects/EBP/conservation/gen_assembly_pipeline/hoolock/hoolock_chrm_3/chr3_ont.fastq.gz"
pb                  :  "/core/projects/EBP/conservation/gen_assembly_pipeline/hoolock/hoolock_chrm_3/chr3_pb.fastq.gz"
ill_1               :  "/core/projects/EBP/conservation/gen_assembly_pipeline/hoolock/hoolock_chrm_3/chr3_ill_R1.paired.fastq.gz"
ill_2               :  "/core/projects/EBP/conservation/gen_assembly_pipeline/hoolock/hoolock_chrm_3/chr3_ill_R2.paired.fastq.gz"
assembly_modules    : ["busco", "merqury"]
longread_modules    : ["all"]
shortread_modules   : ["none"]
manual_genome_size  : "866000000"
outdir              : "output"
existing_assembly   : true
longread_QC         : true
ONT_lr              : true
```

## Assembly Options

- [`Quast v5.2`](https://github.com/ablab/quast)
- [`Busco v5.7.1`](https://gitlab.com/ezlab/busco)
- [`Compleasm v0.2.6`](https://github.com/huangnengCSU/compleasm/tree/0.2.6)
- [`Merqury v1.3`](https://github.com/marbl/merqury)
- [`Meryl v1.3`](https://github.com/marbl/meryl/tree/v1.3-maintenance)

## Long Read Options

### ONT Reads

- [`Nanoplot v1.41`](https://github.com/wdecoster/NanoPlot)
- [`Centrifuge v1.04`](https://ccb.jhu.edu/software/centrifuge/)
- [`Recentrifuge v1.9.1`](https://github.com/khyox/recentrifuge)
- [`KmerFreq`](https://github.com/fanagislab/kmerfreq)
- [`GCE`](https://github.com/fanagislab/GCE)
- [`Seqkit v2.4.0`](https://bioinf.shenwei.me/seqkit/usage/#seq)

### PacBio Reads

- [`Nanoplot v1.41`](https://github.com/wdecoster/NanoPlot)
- [`CutAdapt v3.4`](https://cutadapt.readthedocs.io/en/stable/)
- [`GenomeScope2 v2.0`](http://qb.cshl.edu/genomescope/)
- [`Jellyfish v2.2.6`](https://github.com/gmarcais/Jellyfish)
- [`Kraken2 v2.1.2`](https://ccb.jhu.edu/software/kraken2/)
- [`Recentrifuge v1.9.1`](https://github.com/khyox/recentrifuge)
- [`CutAdapt v3.4`](https://cutadapt.readthedocs.io/en/stable/)

## Short Read Options

- [`FastP v0.23.4`](https://github.com/OpenGene/fastp)
- [`FastQC v0.11.9`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- [`Kraken2 v2.1.2`](https://ccb.jhu.edu/software/kraken2/)
- [`GenomeScope2 v2.0`](http://qb.cshl.edu/genomescope/)
- [`Jellyfish v2.2.6`](https://github.com/gmarcais/Jellyfish)
- [`Recentrifuge v1.9.1`](https://github.com/khyox/recentrifuge)


## Credits

PlantGenomicsLab/qc-nf was written and developed through the combined effort of 
- [Henry Schober](https://github.com/henry-schober)
- [Keertana Chagari](https://github.com/keertanac)
- [Emily Trybulec](https://github.com/emilytrybulec)
- [Gabe Barrett](https://gitlab.com/Gabriel-A-Barrett)
- [Cynthia Webster](https://gitlab.com/cynthiawebster)

__QuaCk__ is based off of [Argonaut](https://github.com/emilytrybulec/argonaut) which is a full genome assembly pipeline written originally by Emily Trybulec

## Citations

References for tools used in the pipeline are found in the [`CITATIONS.md`](CITATIONS.md) file.

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
