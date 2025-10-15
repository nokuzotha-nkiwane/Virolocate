 #!/usr/bin/env bash

module nextflow

NXF_HOME=/analyses/projects/.nextflow

# Set the name with random suffix in a Bash-compatible way
NAME="test-rid$RANDOM"

nextflow run main.nf \
                 -name "$NAME" \
                 -profile test,singularity \
                 -c /analyses/projects/Virolocate/_custom.config \
                 -resume  \
                 --outdir "results/$NAME" \
                 -work-dir "work/$NAME" \
		 --input /analyses/projects/Virolocate/s_sheet.csv 

		 #-entry VIROLOCATE_NF \
