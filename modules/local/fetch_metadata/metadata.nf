process FETCH_METADATA {
    conda "${moduleDir}/environment.yml"
    container "wave.seqera.io/wt/9dc43bf827c0/wave/build:fetch_metadata--94bd174222c6a1e2"
    
    input:
    tuple val(meta), path('*.tsv')

    output:
    tuple val(meta), path('*.tsv')  , emit: blastn_metadata_tsv
    path "versions.yml"             , emit: versions

    script:
    def blasatn_output = task.ext.blasatn_output
    def blastn_metadata_tsv = task.ext.blastn_metadata_tsv

    """
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
        local tax=\$(echo "\${info}" | awk '/\\/db_xref/ { match(\$0, /taxon:([0-9]+)/, tax_id); print tax_id[1] }')

        #split the other columns after the third one
        IFS=\$'\\t' read -r -a rest_array <<< "\${columns}"
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

    while IFS=\$'\\t' read -r col1 col2 col3 rest;do
        echo "[\${col3}]"
        get_meta "\${col1}" "\${col2}" "\${col3}" "\${rest}" "${blastn_metadata_tsv}"
    done < "${blasatn_output}"
    """

    stub:
    def blastn_metadata_tsv = task.ext.blastn_metadata_tsv
    """
    touch blastn_metadata.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fetch_metadata: "1.0.0"
    END_VERSIONS
    """
}