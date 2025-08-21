#!/bin/env bash

#directories
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools"
out="${wdir}/diamond/output"
rv_dir="${out}/RVDB"
nc_dir="${out}/NCBI"

#if working with RVDB, check if RVDB folder exists so if it doesnt only run ncbi part
if [[ ! -d ${rv_dir} ]]; then 
    echo "No RVDB folder exists. Searching for NCBI folder"
else 
echo "Using RVDB folder for blastn file preparation"

    #clear accession id list if existing
    > ${rv_dir}/acc_ids.txt

    #take nucleotide acc_id from diamond output file 
    for matches in ${rv_dir}/*.m8;do
        while read -r col1 col2 col3 rest; do
            acc_id=$(echo ${col3} | cut -d"|" -f5)
            echo -e "${col1}\t${acc_id}"
        done < ${matches} >> ${rv_dir}/acc_ids.txt
    done
fi


#use NCBI database to get taxonomy; check if folder exits first
if [[ ! -d ${nc_dir} ]]; then 
    echo "No NCBI folder exists. Exiting process"
else 
    echo "Using NCBI folder for blastn file preparation"

    #clear accession id list if existing
    > ${nc_dir}/acc_ids.txt

    #take protein acc_id from diamond output file 
    for matches in ${nc_dir}/*.m8;do
        while read -r col1 col2 rest; do
            p_acc_id=$(echo ${col2})
            echo -e "${col1}\t${p_acc_id}"
        done < ${matches} >> ${nc_dir}/p_acc_ids.txt
    done

    #convert the protein accesions to nucleotide ones, make acc_ids.txt output file with contig ids and nucleotide accessions only
    

fi

#if both folders don't exist script should not be executed
if [[ ! -d ${rv_dir} && ! -d ${nc_dir} ]]; then 
    exit 1
fi

#merge the ncbi and rvdb acc_ids files (if both present) and write out to diamond output directory
#if only the ncbi file exists and has a non-empty acc-ids.txt file
if [[ -s ${nc_dir}/acc_ids.txt ]]; then
    cat ${nc_dir}/acc_ids.txt >> ${out}/acc_ids.txt
fi

#if only the rvdb file exists and has a non-empty acc-ids.txt file
if [[ -s ${rv_dir}/acc_ids.txt ]]; then
    cat ${rv_dir}/acc_ids.txt >> ${out}/acc_ids.txt
fi


#sort and deduplicate acc_ids.txt
sort -u ${out}/acc_ids.txt -o ${out}/acc_ids.txt

#function to get taxonomy ids from eutils
function get_tax_id {
    contig=$1
    acc_id=$2
    output=$3


    #get uid first which links the accesion id to the taxonid (filter the json output using jq to get uid)
    url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nuccore&term=${acc_id}&retmode=json"
    uid=$(curl -N -# "${url1}" | tr -d '\r\n' | jq -r '.esearchresult.idlist[0]')


    #get taxon id using uid
    if [[ -n ${uid} ]]; then

        #link to get taxon id using uid
        url2="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=nuccore&id=${uid}&retmode=json" 
        tax_id=$(curl -N -# "${url2}" | tr -d '\r\n' | jq -r ".result[\"${uid}\"].taxid")


        #print output
        echo -e "${contig}\t${acc_id}\t${tax_id}" >>${output}

    #if no taxon id found
    else
        echo -e "${contig}\t${acc_id}\tNOT_FOUND" >> ${output}
    fi

}

#clear output file before each run
output_tsv="${out}/acc_tax_id.tsv"
> ${output_tsv}

while read -r col1 col2;do
    echo "[${col2}]"
    get_tax_id ${col1} ${col2} ${output_tsv}
done < ${out}/acc_ids.txt


#a check through file for taxonomic ids that not have been found
echo "If number below is not 0, please check file for possible values where the taxonomy id was not found"
grep "NOT_FOUND" ${output_tsv} | wc -l

exit 0