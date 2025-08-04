#!/bin/env bash


#directories
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools/diamond/output"
rv_dir="${wdir}/RVDB"
nc_dir="${wdir}/NCBI"
rv_ann="${rv_dir}/annotated"
nc_ann="${nc_dir}/annotated"

#clear existing annotation directories and make new ones in RVDB and NCBI directories
for folder in $(ls ${wdir}/*); do
    if [[ -e ${folder}/annotated ]]; then
        rm -rf ${folder}/annotated
    fi

    ann_dir="${folder}/annotated"
    mkdir -p "${ann_dir}"


    #get nucleotide accession number for RVDB samples
    for file in $(ls ${rv_dir}/*.m8); do
        cat $file | awk '{print $2}' | cut -d '|' -f5  >> "${rv_dir}/${ann_dir}/acc_id_list.txt"
    done

    #get nucleotide accession number for NCBI samples
    for file in $(ls ${nc_dir}/*.m8); do
        awk '{print $2}' ${file} >> ${nc_dir}/${ann_dir}/acc_id_list.txt
    done

    for folder in $(ls ${wdir}/*); do
        sort -u "${ann_dir}/acc_id_list.txt" -o "${ann_dir}/unique_acc_id.txt"
    done
done


#  cat $file | awk '{print $2}' | cut -d '|' -f5  >>${ann_dir}/acc_id_list.txt

#   cat $file | cut -d ',' -f2 | awk '{print $2}' >>${ann_dir}/acc_id_list.txt

# cat K058681_S32_rvdb.matches.m8 | awk '{print $2}' | cut -d '|' -f5  >> acc_id_list.txt