process TAX_IDS{
    input:
    path rvdb_dir 
    path ncbi_dir

    output:
    path "acc_tax_id.tsv", emit: tsv


    script:
    //to change into nextflow logic
    """
    #!/bin/env bash
    set -uex

    rv_acc=${rvdb_dir}/rvdb_acc_ids.tsv
    nc_acc=${ncbi_dir}/ncbi_acc_ids.tsv
    fin_acc=accessions.tsv



    #if working with RVDB, check if RVDB folder exists so if it doesnt only run ncbi part
    if [[ -d ${rvdb_dir} ]]; then 

    echo "Using RVDB folder for metadata file preparation"

    #clear accession id list if existing
    > ${rv_acc}

    #take nucleotide acc_id from diamond output file 
    for matches in ${rvdb_dir}/*.m8;do
        while read -r col1 col2 col3 col4 rest; do
            acc_id=$(echo ${col3} | cut -d "|" -f3)
            name=$(echo ${col4} | cut -d "|" -f6)
            echo -e "${col1}\t${col2}\t${acc_id}\t${name}\t${rest}"
        done < ${matches} 
    done >> ${rv_acc}

    else
        echo "No RVDB folder exists. Searching for NCBI folder"
    fi


    #if both folders don't exist script should not be executed
    if [[ ! -d ${rvdb_dir} && ! -d ${nc_dir} ]]; then 
        echo "No NCBI folder exists. Exiting process."
        exit 1
    fi

    #merge the ncbi and rvdb acc_ids files and write out to diamond output directory
    #if the rvdb file exists and has a non-empty acc-ids.txt file
    if [[ -s ${rv_acc} ]]; then
        cat ${rv_acc} >> ${fin_acc}
    fi

    #if the ncbi file exists and has a non-empty acc-ids.txt file
    if [[ -s ${nc_acc} ]]; then 
        echo "Using NCBI folder for metadata file preparation"
        for matches in ${nc_dir}/*.m8; do
            cat ${matches} >> ${fin_acc}
        done
    fi

    #sort and deduplicate acc_ids.txt
    sort -u ${fin_acc} -o ${fin_acc}

    #function to get metadata from eutils
    function get_meta {
        contig=$1
        length=$2
        acc_id=$3
        columns=$4
        output=$5


        #print ncbi page of protein accession and parse taxonomic id for use in taxonkit for lineage
        url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=${acc_id}&rettype=gb&retmode=text"
        info=$(curl -N -# ${url1})
        #host source, gographical location name, collection date, gene, product, taxonomic number
        host=$(echo "${info}" | awk -F'"' '/\/host/ {print $2}')
        geo_loc_name=$(echo "${info}" | awk -F'"' '/\/geo_loc_name/ {print $2}')
        date=$(echo "${info}" | awk -F'"' '/\/collection_date/ {print $2}')
        gene=$(echo "${info}" | awk -F'"' '/\/coded_by/ {print $2}')
        product=$(echo "${info}" | awk -F'"' '/\/product/ {print $2}')
        tax=$(echo "${info}" | awk '/\/db_xref/ { match($0, /taxon:([0-9]+)/, tax_id); print tax_id[1] }')

        #split the other columns after the third one
        IFS=$'\t' read -r -a rest_array <<< ${columns}
        rest=$(printf "%s\t" "${rest_array[@]}" )

        #print output
        echo -e "${contig}\t${length}\t${acc_id}\t${rest}\t${host}\t${gene}\t${product}\t${geo_loc_name}\t${date}\t${tax}" >>${output}


    } 

    #clear output file before each run
    > ${output_tsv}

    while IFS=$'\t' read -r col1 col2 col3 rest;do
        echo "[${col3}]"
        get_meta ${col1} ${col2} ${col3} ${rest} ${output_tsv}
    done < ${fin_acc}

    """
}