#!/bin/env bash

#directories
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools"
out="${wdir}/diamond/output"
rv_dir="${out}/RVDB"
nc_dir="${out}/NCBI"
output_tsv="${out}/acc_tax_id.tsv"

#if working with RVDB, check if RVDB folder exists so if it doesnt only run ncbi part
if [[ -d ${rv_dir} ]]; then 

    echo "Using RVDB folder for taxonomy ID file preparation"

    #clear accession id list if existing
    > ${rv_dir}/acc_ids.txt

    #take nucleotide acc_id from diamond output file 
    for matches in ${rv_dir}/*.m8;do
        while read -r col1 col2 col3 rest; do
            acc_id=$(echo ${col3} | cut -d "|" -f3)
            echo -e "${col1}\t${acc_id}"
        done < ${matches} 
    done >> ${rv_dir}/acc_ids.txt

else
    echo "No RVDB folder exists. Searching for NCBI folder"
fi


#use NCBI database to get taxonomy; check if folder exits first
if [[ -d ${nc_dir} ]]; then 
    echo "Using NCBI folder for taxonomy ID file preparation"

    #clear accession id list if existing
    > ${nc_dir}/acc_ids.txt
  
    #extract contig ids and protein accessions from resulting matches
    for matches in ${nc_dir}/*.m8;do
    while read -r col1 col2 col3 rest; do
        echo "Making file with protein accession IDs and associated contig ids"
        echo -e "${col1}\t${col3}"
    done < ${matches} 
    done >> ${nc_dir}/acc_ids.txt

else
    echo "No NCBI folder exists"
fi


#if both folders don't exist script should not be executed
if [[ ! -d ${rv_dir} && ! -d ${nc_dir} ]]; then 
    echo "No RVDB or NCBI folder with Diamond Blastx output exist. Exiting process."
    exit 1
fi

#merge the ncbi and rvdb acc_ids files and write out to diamond output directory
#if the rvdb file exists and has a non-empty acc-ids.txt file
if [[ -s ${rv_dir}/acc_ids.txt ]]; then
    cat ${rv_dir}/acc_ids.txt >> ${out}/acc_ids.txt
fi

#if the ncbi file exists and has a non-empty acc-ids.txt file
if [[ -s ${nc_dir}/acc_ids.txt ]]; then
    cat ${nc_dir}/acc_ids.txt >> ${out}/acc_ids.txt
fi

#sort and deduplicate acc_ids.txt
sort -u ${out}/acc_ids.txt -o ${out}/acc_ids.txt

#function to get taxonomy ids from eutils
function get_tax_id {
    contig=$1
    acc_id=$2
    output=$3


    #print ncbi page of protein accession and parse taxonomic id for use in taxonkit for lineage
    url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=${acc_id}&rettype=gb&retmode=text"
    tax=$(curl -N -# ${url1} | awk '/\/db_xref/ { match($0, /taxon:([0-9]+)/, tax_id); print tax_id[1] }')

    #print output
    echo -e "${contig}\t${acc_id}\t${tax}" >>${output}


}

#clear output file before each run
> ${output_tsv}

while read -r col1 col2;do
    echo "[${col2}]"
    get_tax_id ${col1} ${col2} ${output_tsv}
done < ${out}/acc_ids.txt


#a check through file for taxonomic ids that not have been found
# echo "If number below is not 0, please check file for possible values where the taxonomy id was not found"
# grep "NOT_FOUND" ${output_tsv} | wc -l

exit 0