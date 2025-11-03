#!/usr/bin/env bash

module nextflow

export NXF_HOME=/projects/.nextflow/proj-virolocate-nokuzotha
export SINGULARITY_TMPDIR=/analyses/.TMP/proj-virolocate-nokuzotha
export NXF_SINGULARITY_CACHEDIR=/analyses/.TMP/proj-virolocate-nokuzotha
export TOWER_API_ENDPOINT=https://api.tower.nf
export TOWER_ACCESS_TOKEN=
export TOWER_WORKSPACE_ID=

# Set the name with random suffix in a Bash-compatible way
NAME="dev-rid$RANDOM"
INPUT="/analyses/projects/proj-virolocate-nokuzotha2/sra_samplesheet.csv"
#SAMPLESHEET="/projects/proj-virolocate-nokuzotha/samplesheet.csv"

nextflow run 'https://github.com/nokuzotha-nkiwane/Virolocate.git' \
                 -name "$NAME" \
                 -profile test,singularity \
                 -r optimisation -latest -resume \
                 -work-dir "/analyses/.TMP/work" \
                 --outdir "_deleteme/results_test" \
                 --input  "/analyses/projects/proj-virolocate-nokuzotha2/sra_samplesheet.csv" \
                 -dump-channels