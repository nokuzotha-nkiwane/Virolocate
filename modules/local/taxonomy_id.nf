process TAX_IDS{

    conda 'bioconda::curl'

    input:
    path rvdb_dir 
    path ncbi_dir

    output:
    path "../output", emit: out_dir
    path "\${out_dir}/acc_tax_id.tsv", emit: tsv


    script:
    //to change into nextflow logic
    """
    #!/bin/env bash
    set -uex

    #set file variables
    rv_acc=\${rvdb_dir}/rvdb_acc_ids.tsv
    nc_acc=\${ncbi_dir}/ncbi_acc_ids.tsv
    fin_acc=\${out_dir}/accessions.tsv
    output_tsv=\${out_dir}/acc_tax_id.tsv

    #clear existing files
    > \${rv_acc}
    > \${nc_acc}
    > \${fin_acc}
    > \${output_tsv}

    #if working with RVDB, check if RVDB folder exists and isn't empty; if it doesnt only run ncbi part
    if [[ -d "${rvdb_dir}" ]] && [[ \$(find "${rvdb_dir}" -name "*.m8" | wc -l) -gt 0 ]]; then 

        #check for empty files and skip them
        for matches in "${rvdb_dir}"/*.m8;do
            if [[ -f "\${matches}" ]]; then
                
                #take nucleotide acc_id from diamond output file 
                while read -r col1 col2 col3 col4 rest; do
                    acc_id=\$(echo "\${col3}" | cut -d "|" -f3)
                    name=\$(echo "\${col4}" | cut -d "|" -f6)
                    echo -e "\${col1}\\t\${col2}\\t\${acc_id}\\t\${name}\\t\${rest}"
                done < "\${matches}" 
            fi
        done >> "\${rv_acc}"

    #if directory or files empty
    else
        echo "RVDB directory does not exist. Searching for NCBI directory."
    fi


    #if both folders don't exist script should not be executed
    if [[ ! -d "${rvdb_dir}" && ! -d "${ncbi_dir}" ]] | [[ \$(find "${rvdb_dir}" -name "*.m8" | wc -l) -eq 0 && \$(find "${ncbi_dir}" -name "*.m8" | wc -l) -eq 0 ]]; then 
        echo "No NCBI folder exists. Exiting process."
        exit 1
    fi

    #merge the ncbi and rvdb acc_ids files and write out to diamond output directory
    #if the rvdb file exists and has a non-empty acc-ids.txt file
    if [[ -s "\${rv_acc}" ]]; then
        cat "\${rv_acc}" >> "\${fin_acc}"
    fi

    #if the ncbi file exists and has a non-empty acc-ids.txt file
    if [[ -d "${ncbi_dir}" ]] && [[ \$(find "${ncbi_dir}" -name "*.m8" | wc -l) -gt 0 ]]; then 
        echo "Using NCBI folder for metadata file preparation"
        for matches in "${ncbi_dir}"/*.m8; do
                #if [[ -s "\${matches}" ]];then
                cat "\${matches}" >> "\${fin_acc}"

            else
                echo "Files in NCBI directory empty or do not exist."
            fi
        done

    else 
        echo "NCBI directory does not exist or is empty"

    fi

    #sort and deduplicate acc_ids.txt
    if [[ -s "\${fin_acc}" ]];then
        sort -u "\${fin_acc}" -o "\${fin_acc}"

    else
        echo -e "Accessions file "\${fin_acc}" not found.)"
        exit 1
    fi



    #function to get metadata from eutils
    get_meta() {
    
    local contig=\$1
    local length=\$2
    local acc_id=\$3
    local columns=\$4
    local output=\$5
    
    #print ncbi page of protein accession and parse taxonomic id for use in taxonkit for lineage
    local url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=${acc_id}&rettype=gb&retmode=text"
    local info=\$(curl -N -# \${url1})

    #host source, gographical location name, collection date, gene, product, taxonomic number
    local host=\$(echo "\${info}" | awk -F'"' '/\/host/ {print \$2}')
    local geo_loc_name=\$(echo "\${info}" | awk -F'"' '/\/geo_loc_name/ {print \$2}')
    local date=\$(echo "\${info}" | awk -F'"' '/\/collection_date/ {print \$2}')
    local gene=\$(echo "\${info}" | awk -F'"' '/\/coded_by/ {print \$2}')
    local product=\$(echo "\${info}" | awk -F'"' '/\/product/ {print \$2}')
    local tax=$(echo "\${info}" | awk '/\/db_xref/ { match(\$0, /taxon:([0-9]+)/, tax_id); print tax_id[1] }')

    #split the other columns after the third one
    IFS=$'\t' read -r -a rest_array <<< ${columns}
    rest=$(printf "%s\t" "\${rest_array[@]}" )

    #print output
    echo -e "\${contig}\\t\${length}\\t\${acc_id}\\t\${rest}\\t\${host}\\t\${gene}\\t\${product}\\t\${geo_loc_name}\\t\${date}\\t\${tax}" >>\${output}

    } 

    #clear output file before each run
    > "\${output_tsv}"

    while IFS=$'\t' read -r col1 col2 col3 rest;do
        echo "[\${col3}]"
        get_meta \${col1} \${col2} \${col3} \${rest} \${output_tsv}
    done < "\${fin_acc}"

    """
}