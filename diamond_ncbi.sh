#!/bin/env bash

#directories
wdir="/analyses/users/nokuzothan/disc_pipe"
cdir="${wdir}/init_tools/diamond/output"
db_coll="${wdir}/ncbidb/nr"
db_fastas="${cdir}/db_fastas"
db_output="${cdir}/databases"

#make directory to recieve fastas
if [[ -e ${db_fastas} ]]; then
  rm -rf ${db_fastas} 
fi
mkdir -p -m a=rwx ${db_fastas}

#make directory for diamond made databases
if [[ -e ${db_output} ]]; then
  rm -rf ${db_output} 
fi
mkdir -p -m a=rwx ${db_output}

#function to unzip each database batch and make a diamond database with resulting fastas
function db_make() {
    db_zipped=$1
    db_fasta_loc=$2
    output=$3

    #unzip db_zipped from db_collection to a new location while keeping original zipped file 
    tar -xzf ${db_zipped} -C ${db_fasta_loc}

    #fasta file base names and locations
    find "${db_fasta_loc}" -name '*.fasta' -o -name '*.fa' | while read -r fasta_file; do
        name=$(basename "${fasta_file}")
        out_db="${output}/${base_name%.fa*}"

    #make database from fasta
    diamond makedb --in ${fasta_file} -d ${out_}
}
export -f db_make

while read -r ${db_coll}/nr.*.tar.gz; do
    ls ${db_coll}/nr.*.tar.gz | parallel -j 10 -n1 -I% db_make % ${db_fastas} ${db_fastas}/nr.*.fasta ${output}/nr 
done

#db_fastas used can now be deleted
if [[ -e ${db_fastas} ]]; then
  rm -rf ${db_fastas} 
fi





#ls ${db_fasta}/nr.*.tar.gz | cut -d '.' -f1,2 | parallel -j 10 -n1 -I% "db_make % ${output}/nr"

parallel -j 10 -n1 -I% db_make ${db_fasta}/nr.*.tar.gz ${output}/nr


#ls ${db_fasta}/nr.*.tar.gz | cut -d '.' f1,2 | parallel -j 10 -n1 -I% "DBX % ${output}"
#ls | cut -d '.' f1,2 | parallel -j 10 -n1 -I% "DBX % ${fasta} ${wdir} ${output}"