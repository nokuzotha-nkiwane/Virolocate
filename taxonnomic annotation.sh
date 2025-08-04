#!/bin/env bash

#directories
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools/diamond/output"


#clear existing annotation directories and make new ones in RVDB and NCBI directories
for folder in ${wdir}/*; do
    if [[ -e ${folder}/annotated ]]; then
        rm -rf ${folder}/annotated
    fi

    ann_dir="${folder}/annotated"
    [ -d "${folder}" ] && mkdir -p "${ann_dir}"
    
    #if accession id list already exists remove it
    #> ${ann_dir}/acc_id_list.txt

    #writing and appending accession ids of new run
    for file in ${folder}/*.m8;do
        cat $file | cut -d ',' -f2 | awk '{print $2}' >>${ann_dir}/acc_id_list.txt
    done

    #remove duplications in list
    sort -u "${ann_dir}/acc_id_list.txt" -o "${ann_dir}/unique_acc_id.txt"

    #get the taxonomy id for each accession id
    while read -r acc; do
        esummary -db protein -id "${acc}" | xtract -pattern DocumentSummary -element AccessionVersion,TaxId >> "${ann_dir}/acc_tax_id.tsv"
        #time delay for NCBI's 3 requests/second rule
        sleep 0.34 
    done < "${ann_dir}/unique_acc_id.txt"

    #get annotation file for each taxonomy id (take out taxonomic ids first just like acc_ids)
    cut -f2 ${ann_dir}/acc_tax_id.tsv >> ${ann_dir}/acc_tax_id.txt

    #remove duplications in list
    sort -u "${ann_dir}/acc_tax_id.txt" -o "${ann_dir}/unique_acc_tax_id.txt"

    #get annotations for each taxonomy id (same as previous but use efetch)
    while read taxid; do 
        efetch -db taxonomy -id "${taxid}" -format xml | xtract -pattern Taxon -element TaxId,ScientificName,Lineage >> "${ann_dir}/tax_id_annotation.tsv"
        sleep 0.34 
    done < ${ann_dir}/unique_acc_tax_id.txt

    #split the lineage column in tax_id_annotation.tsv so each detail has its own column
    awk -F '\t' 'BEGIN {

    #makes sure output file will be tab-separated
    OFS = "\t"  
    }
        #assign columns to variables
        tax_id = $1
        sci_name = $2 
        lineage_info = $3

        #break up the lineage information at semi-colon and save to array called lineage
        split(lineage_info, lineage, "; ")

        #print first two colums (taxid and scientific name)
        printf "%s\t%s", taxid, name 

        #iterate through lineage array made above and print each item to own column
        for (i = 1; i <= length(lineage); i++) {
            printf "\t%s", lineage[i]
        }

        #ends the line so operation moves to next item and line
        print ""

    ' ${ann_dir}/tax_id_annotation.tsv >> ${ann_dir}/split_annotation.tsv
done




