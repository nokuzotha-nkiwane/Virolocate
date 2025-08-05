#!/bin/env bash

#load module
module diamond

#directories
wdir="/analyses/users/nokuzothan/disc_pipe"
cdir="${wdir}/init_tools/diamond/output"
db="${wdir}/ncbidb/fasta/nr.gz"

#unzip db_zipped from db_collection to a new location while keeping original zipped file 
gunzip -c ${db} | diamond makedb --in % -d ${cdir}


