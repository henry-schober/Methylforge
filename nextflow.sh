#!/bin/bash
#SBATCH --job-name=QuaCk_test
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mail-user=henry.schober@uconn.edu
#SBATCH --mem=20G
#SBATCH --gres=gpu:A100:1
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err

module load nextflow

export TEMPDIR=$PWD/tmp
nextflow run main.nf -profile test,mantis --input samplesheet.csv -resume
