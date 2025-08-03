#!/bin/env bash

#directories
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools/diamond/output"
rv_dir="${wdir}/RVDB"
nc_dir="${wdir}/NCBI"
out_rv="${rv_dir}/annotated"
out_nc="${nc_dir}/annotated"
tmp="${wdir}/TMP"

#make directories if they do not exist; remove if they already do
if [[ -e ${out_rv} ]]; then
    rm ${out_rv}
fi
mkdir -p a=wrx ${out_rv}

if [[ -e ${out_nc} ]]; then
    rm ${out_nc}
fi
mkdir -p a=wrx ${out_nc}

if [[ -e ${tmp} ]]; then
    rm ${tmp}
fi
mkdir -p a=wrx ${tmp}

#loop through diamond output folder for .m8 matches files
for file in ${rv_dir}/*.m8; do
    sample=$(basename ${file} .matches.m8)
    tax_ann_rv=${out_rv}/${sample}_annotated.m8









    tax_ann_nc=${out_nc}/${sample}_annotated.m8
