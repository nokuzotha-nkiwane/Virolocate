#!/bin/env bash

#load modules 
ON="module miniconda && conda activate ncbi-datasets"
eval ${ON}

#directories
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools/diamond/output"
rv_dir="${wdir}/RVDB"
nc_dir="${wdir}/NCBI"
rv_ann="${rv_dir}/annotated"
nc_ann="${nc_dir}/annotated"

#clear existing annotation directories and make new ones in RVDB and NCBI directories
for folder in (ls ${wdir})/*; do
    if [[ -e ${folder}/annotated ]]; then
        rm -rf ${folder}/annotated
    fi

    ann_dir="${folder}/annotated"
    mkdir -p "${ann_dir}"
done

#get nucleotide accession number for RVDB samples
awk '{print $2}' (ls ${rv_dir}/*.m8) | cut -d '|' -f5  >> "${rv_ann}/acc_id_list.txt"

#function to convert NCBI protein accession to nucleotide accession
function prot_to_nt() {
    prot_acc=$1
    output=$2
    url="https://api.ncbi.nlm.nih.gov/datasets/v2alpha/protein/accession/${prot_acc}"

    nt=`curl ${url} | jq -r '.protein.annotated_rna.accession // "NA"'`
    echo -e "${prot_acc}\t${nt}" >> ${output}
}
export -f prot_to_nt

#get nucleotide accession number for NCBI samples
awk '{print $2}' (ls ${nc_dir}/*.m8) | sort -u > "${nc_ann}/prot_id_list.txt"

while read -r prot_acc;do
    prot_to_nt ${prot_acc} "${nc_ann}/acc_id_list.txt"
    echo "Nucleotide accession found for ${prot_acc}"
done < "${nc_ann}/prot_id_list.txt"


#function to run each accession_id list through datasets to get taxonomic id
function taxon_info() {
    acc_id=$1
    output=$2
    url="https://api.ncbi.nlm.nih.gov/datasets/v2/genome/accession/${acc_id}/"
    #url2=""
    
    #get taxonomic ids acc accession id
    meta_data=`curl -s ${url}`
    tax_id=`echo ${meta_data} | jq -r ' .genome.taxonomy.taxonomy_id // "NA"'`
    name=`echo ${meta_data} | jq -r ' .genome.taxonomy.organism // "NA"'`
    rank=`echo ${meta_data} | jq -r ' .genome.taxonomy.rank // "NA"'`
    lineage=`echo ${meta_data} | jq -r 'try ([.genome.taxonomy.lineage[].organism] | join("\t")) catch "NA"'`
    
    #print acccession id and taxon info
    echo -e "${acc_id}\t${tax_id}\t${name}\t${rank}\t${lineage}" >> ${output}
}
export -f taxon_info

#sort and remove duplications in lists
for ann_dir in (ls ${wdir}/*/annotated); do
    if [[ -f ${ann_dir}/acc_id_list.txt ]]; then
        sort -u "${ann_dir}/acc_id_list.txt" -o "${ann_dir}/unique_acc_id.txt"

    #get taxon_info for each annotated directory
    while read -r acc_id;do
    taxon_info "${acc_id}" "${ann_dir}/taxonomy.tsv"
    
    #progress check
    echo "Taxonomic information for ${acc_id} retrieved"
    done < "${ann_dir}/unique_acc_id.txt"
    fi
done


#cross-ref taxonomic info


#  cat $file | awk '{print $2}' | cut -d '|' -f5  >>${ann_dir}/acc_id_list.txt

#   cat $file | cut -d ',' -f2 | awk '{print $2}' >>${ann_dir}/acc_id_list.txt

# cat K058681_S32_rvdb.matches.m8 | awk '{print $2}' | cut -d '|' -f5  >> acc_id_list.txt
