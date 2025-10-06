 #!/usr/bin/env bash

module nextflow

NXF_HOME=/analyses/download/.nextflow

# Set the name with random suffix in a Bash-compatible way
NAME="test-rid$RANDOM"

nextflow run main.nf \
                 -name "$NAME" \
                 -profile singularity \
                 -c /analyses/users/nokuzothan/Virolocate/custom.config \
                 -resume  \
                 --outdir "results/$NAME" \
                 -work-dir "work/$NAME"
