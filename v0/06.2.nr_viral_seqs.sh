#!/bin/env bash

# variables and directories
wdir="/analyses/users/nokuzothan/disc_pipe"
cdir="${wdir}/init_tools/diamond/input"
viruses_csv="${cdir}/virus_taxonomy_lvls.csv"
names="${cdir}/viral_namess.txt"
db="${wdir}/ncbidb/fasta/nr.faa"
db_fasta="${cdir}/ncbi_fasta.faa"
threads=$((`/bin/nproc` -2))


#filter csv for viral sequences
awk -F',' '{print $3}' ${viruses_csv} >> ${names}

#filter nr database for viral sequences 
while read -r virus; do
    awk -v name="${virus}" '
        BEGIN {IGNORECASE=1}
        /^>/ {ON = index($0, name) > 0}
        ON {print}
    ' ${db} >> ${db_fasta}
done < ${names}
