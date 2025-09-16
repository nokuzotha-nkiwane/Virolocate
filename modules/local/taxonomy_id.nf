process TAXONOMY_ID {

    conda 'bioconda::curl'

    input:
    tuple val(meta), path('*.tsv')
    tuple val(meta), path('*.tsv')

    output:
    tuple val(meta), path('*.tsv'), emit: final_accessions_tsv
    tuple val(meta), path('*.tsv'), emit: acc_tax_id_tsv
    val "TAXONOMY_ID v1.0.0" into version

    script:
    """
    rvdb_acc="rvdb_final_accessions.tsv"
    ncbi_acc="ncbi_final_accessions.tsv"
    fin_acc="final_accessions.tsv"
    output_tsv="acc_tax_id.tsv"

    #combine rvdb_final_accessions.tsv and ncbi_final_accessions.tsv
    if [[ -s "\${rvdb_acc}" && -s "\${ncbi_acc}" ]];then
        cat "\${rvdb_acc}" "\${ncbi_acc}" > "\${fin_acc}"

    #if only rvdb accessions file exists
    elif [[ -s "\${rvdb_acc}" ]]; then
        cp "\${rvdb_acc}" "\${fin_acc}"

    #if only ncbi accessions file exists
    elif [[ -s "\${ncbi_acc}" ]]; then
        cp "\${ncbi_acc}" "\${fin_acc}"
    
    #if neither accessions files exists
    else
        echo -e "Accessions file "\${fin_acc}" not found."
        exit 1
    fi

    #sort and deduplicate acc_ids.txt
    sort -u "\${fin_acc}" -o "\${fin_acc}"

    #function to get metadata from eutils
    get_meta() {

        local contig=\$1
        local length=\$2
        local acc_id=\$3
        local columns=\$4
        local output=\$5

        #progress check
        echo "Fetching metadata for "\${acc_id}"
        #print ncbi page of protein accession and parse taxonomic id for use in taxonkit for lineage
        local url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=\${acc_id}&rettype=gb&retmode=text"
        local info=\$(curl -N -# \${url1})

        #host source, gographical location name, collection date, gene, product, taxonomic number
        local host=\$(echo "\${info}" | awk -F'"' '/\\/host/ {print \$2}')
        local geo_loc_name=\$(echo "\${info}" | awk -F'"' '/\\/geo_loc_name/ {print \$2}')
        local date=\$(echo "\${info}" | awk -F'"' '/\\/collection_date/ {print \$2}')
        local gene=\$(echo "\${info}" | awk -F'"' '/\\/coded_by/ {print \$2}')
        local product=\$(echo "\${info}" | awk -F'"' '/\\/product/ {print \$2}')
        local tax=$(echo "\${info}" | awk '/\\/db_xref/ { match(\$0, /taxon:([0-9]+)/, tax_id); print tax_id[1] }')

        #split the other columns after the third one
        IFS=$'\\t' read -r -a rest_array <<< "\${columns}"
        rest=\$(printf "%s\\t" "\${rest_array[@]}" )

        #put NA if any of the fields are empty
        if [[ -z "\${host}" ]]; then
            host="NA"
        fi

        if [[ -z "\${geo_loc_name}" ]]; then
            geo_loc_name="NA"
        fi

        if [[ -z "\${date}" ]]; then
            date="NA"
        fi

        if [[ -z "\${gene}" ]]; then
            gene="NA"
        fi

        if [[ -z "\${product}" ]]; then
            product="NA"
        fi

        if [[ -z "\${tax}" ]]; then
            tax="NA"
        fi

        #print output
        echo -e "\${contig}\\t\${length}\\t\${acc_id}\\t\${rest}\\t\${host}\\t\${gene}\\t\${product}\\t\${geo_loc_name}\\t\${date}\\t\${tax}" >>\${output}

    }

    #clear output file before each run
    > "\${output_tsv}"

    while IFS=$'\\t' read -r col1 col2 col3 rest;do
        echo "[\${col3}]"
        get_meta "\${col1}" "\${col2}" "\${col3}" "\${rest}" "\${output_tsv}"
    done < "\${fin_acc}"

    """

    stub:
    """

    """
}
