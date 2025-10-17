# MethylForge

## Introduction

**MethylForge** is a DNA Methylation pipeline specifically for ONT Reads. 

## Table of Contents
- [Quick Start](#quick-start)
- [Example](#example-run)
- [Pipeline Output](#output)
- [Citations](#citations)


## Quick Start

### Running the Pipeline

First pull the pipeline from github

`nextflow pull henry-schober/Methylforge -hub github -r main`

#### The typical command to run is as follows:

```bash
nextflow run main.nf \
  -profile test,mantis \
  --input samplesheet_test.csv \
  -params-file params.yaml
```

## Samplesheet layout

`samplesheet.csv`:

```csv
sample,pod5_file,base_model,mod_model
test_name,/path/to/pod5_files_or_directory,/path/to/base_model,/path/to/modified_model
test_name,/path/to/pod5_files_or_directory,/path/to/base_model,,
test_name,/path/to/pod5_files_or_directory,,,
```

> Both Sample Name and Pod5 files are mandatory inputs. Base model and modified model are optional if you have already downloaded the models and want to use that path. If not, models will be downloaded using parameters.

### See [parameter documentation](./docs/Parameters.md) for details on model customizations

## Params.yaml Layout

`params.yaml`

```yaml
input                  :  "/home/FCAM/hschober/methyl_pipeline/MethylForge/qc-nf/samplesheet.csv"
outdir                 :  "/home/FCAM/hschober/methyl_pipeline/MethylForge/test_output"
pore_type              :  "r10.4.1"
chemistry_type         :  "e8.2"
translocation_speed    :  "400bps"
model_version          :  "v5.0.0"
modification_name      :  "5mCG_5hmCG"
modification_version   :  "v3"
model_type             :  "sup"
```


## Example run

This pipelne comes preload with an example pod5 file found in `./sample_data/`

First pull form github repo

`nextflow pull henry-schober/Methylforge -hub gitlab -r main`

Then run pipeline in CLI using this command

`nextflow run henry-schober/Methylforge -r main.nf -profile test,mantis --input samplesheet_test.csv`

## Output

The Outputs are currently located in the output directory specificed in profile or `params.yaml`

```
├── DORADO
│   ├── DORADO MODELS
|   |   ├── DOWNLOAD
|   |   |   ├── dorado models
│   ├── BASE_CALLER
│   |   ├── TEST NAME
|   |   |   ├── bam file
```

## Citations

References for tools used in the pipeline are found in the [`CITATIONS.md`](CITATIONS.md) file.

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
