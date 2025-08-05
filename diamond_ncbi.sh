#!/bin/env bash

#directories
wdir="/analyses/users/nokuzothan/disc_pipe"
cdir="${wdir}/init_tools/diamond/output"
db_fasta="${wdir}/ncbidb/nr"
output="${cdir}/databases"

#make cdir
if [[ -e $output ]]; then
  rm -rf ${output} 
fi
mkdir -p -m a=rwx ${output}

function dbx() {
    db=$1;output=$2
    diamond makedb --in ${db} -d ${output}/nr
}




ls ${db_fasta}/nr.*.tar.gz | cut -d '.' f1,2 | parallel -j 10 -n1 -I% "DBX % ${fasta} ${output}" "





ls | cut -d '.' f1,2 | parallel -j 10 -n1 -I% "DBX % ${fasta} ${wdir} ${output}"