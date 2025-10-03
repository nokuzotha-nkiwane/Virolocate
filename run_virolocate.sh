 #!/usr/bin/env bash

module nextflow

NXF_HOME=/analyses/.nextflow

# Set the name with random suffix in a Bash-compatible way
NAME="test-$1-rid$RANDOM"

nextflow run 'https://github.com/nokuzotha-nkiwane/Virolocate.git' \
                 -name "$NAME" \
                 -profile singularity \
                 -c /analyses/users/nokuzothan/Virolocate/custom.config \
                 -r develop -latest -resume  \
                 --outdir "results/$NAME" \
                 -work-dir "work/$NAME"