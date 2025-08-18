#!/bin/env bash

#load modules
module ncbi

#directories
wdir="/analyses/users/nokuzothan/disc_pipe"
db_fa="${wdir}/ncbidb/nt/nt"
diamond_out="${wdir}/init_tools/diamond/output"
input_fa="${diamond_out}/blastn_fasta"
blastn_out="${wdir}/init_tools/blastn/output"
output="${blastn_out}/blastn_output.tsv"
threads=$((`/bin/nproc` -2))

#make blastn_results subdirectory in blastn output folder
if [[ -e ${blastn_out} ]]; then
    rm -rf ${blastn_out}
fi
mkdir -p -m a=rwx ${blastn_out}

#format fasta to database
 #parse_seqids keeps the names, without it, it makes randomised names
 #max_file_size 4
#makeblastdb -in ${db_fa} -dbtype nucl -out ${blastn_out}/blastn_db -parse_seqids

#blastn run
if [[ -s ${input_fa} ]]; then
    blastn -query ${input_fa} \
        -db ${db_fa} \
        -out ${output}\
        -strand both \
        -num_threads ${threads} \
        -evalue 1E-5 \
        -outfmt "6 qseqid qlen sseqid stitle pident length qstart qend evalue bitscore" \
        -perc_identity 80

else
    echo "Query fasta file of samples does not exist or is empty, skipping blastn."
fi

exit 0