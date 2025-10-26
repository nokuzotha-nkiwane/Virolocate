process FETCH_METADATA_BLASTX_2{
    label 'process_high'
    label 'process_long'
    
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/9dc43bf827c0/wave/build:fetch_metadata--94bd174222c6a1e2"
    
    input:
    tuple val(meta), path(txt)

    output:
    tuple val(meta), path('*_blastx_metadata.tsv')  , emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    get_meta() {

        local contig=\$1
        local acc_id=\$2
        local rest=\$3
        local output=\$4

        #progress check
        echo "Fetching metadata for "\${acc_id}""
        #print ncbi page of protein accession and parse taxonomic id for use in taxonkit for lineage
        local url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=\${acc_id}&rettype=gb&retmode=text"
        local info=\$(curl -N -# -L --retry 5 --retry-delay 5 --max-time 15 --connect-timeout 10 \${url1})

        #host source, gographical location name, collection date, gene, product, taxonomic number
        local host=\$(echo "\${info}" | awk -F'"' '/\\/host/ {print \$2; exit}')
        local geo_loc_name=\$(echo "\${info}" | awk -F'"' '/\\/geo_loc_name/ {print \$2; exit}')
        local date=\$(echo "\${info}" | awk -F'"' '/\\/collection_date/ {print \$2; exit}')
        local gene=\$(echo "\${info}" | awk -F'"' '/\\/coded_by/ {print \$2; exit}')
        local product=\$(echo "\${info}" | awk -F'"' '/\\/product/ {print \$2; exit}')
        local tax=\$(echo "\${info}" | awk '/\\/db_xref/ { match(\$0, /taxon:([0-9]+)/, tax_id); print tax_id[1]; exit }')

        #put NA if any of the fields are empty
        if [[ -z "\${host}" ]]; then
            host="NA"
        else
            host=\$(printf "%s" "\$host" | tr -d '\\n')
        fi

        if [[ -z "\${geo_loc_name}" ]]; then
            geo_loc_name="NA"
        else
            geo_loc_name=\$(printf "%s" "\$geo_loc_name" | tr -d '\\n')
        fi


        if [[ -z "\${date}" ]]; then
            date="NA"
        else
            date=\$(printf "%s" "\$date" | tr -d '\\n')
        fi


        if [[ -z "\${gene}" ]]; then
            gene="NA"
        else
            gene=\$(printf "%s" "\$gene" | tr -d '\\n')
        fi


        if [[ -z "\${product}" ]]; then
            product="NA"
        else
            product=\$(printf "%s" "\$product" | tr -d '\\n')
        fi


        if [[ -z "\${tax}" ]]; then
            tax="NA"
        else
            tax=\$(printf "%s" "\$tax" | tr -d '\\n')
        fi

        #print output
        echo -e "\${contig}\\t\${acc_id}\\t\${rest}\\t\${tax}\\t\${host}\\t\${gene}\\t\${product}\\t\${geo_loc_name}\\t\${date}" >>\${output}

    }

    if [[ ! -s ${txt} || \$(grep -cv '^[[:space:]]*\$' ${txt}) -eq 0 ]]; then
            echo > "${name}_blastn_metadata2.tsv"
    else
        while IFS=\$'\\t' read -r col1 col2 col3 rest;do
            tmpfile=\$(mktemp)
            get_meta "\${col1}" "\${col2}" "\${rest}" "\$tmpfile"
            cat "\$tmpfile" >> "${name}_blastx_metadata.tsv"
            rm "\$tmpfile"
        done < "${txt}"
    fi
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fetch_metadata_blastx: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch blastx_metadata.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fetch_metadata_blastx: "1.0.0"
    END_VERSIONS
    """
}