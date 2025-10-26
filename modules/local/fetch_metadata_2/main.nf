process FETCH_METADATA_BLASTN_2 {
    maxForks 3
    label 'process_long'
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/9dc43bf827c0/wave/build:fetch_metadata--94bd174222c6a1e2"
    
    input:
    tuple val(meta), path(txt)

    output:
    tuple val(meta), path('*_blastn_metadata2.tsv')  , emit: tsv
    path "versions.yml"             , emit: versions

    script:
    def name = txt.getBaseName()
    """
    get_meta() {

        local contig=\$1
        local col=\$2
        local rest=\$3
        local output=\$4

        local acc_id=\$(echo "\${col}" | awk -F'|' '{print \$4}')

        #progress check
        echo "Fetching metadata for "\${acc_id}""
        #print ncbi page of protein accession and parse taxonomic id for use in taxonkit for lineage
        local url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=\${acc_id}&rettype=gb&retmode=text"
        local info=\$(curl -N -# -L --retry 5 --retry-delay 5 --max-time 15 --connect-timeout 10 \${url1})

        #host source, gographical location name, collection date, gene, product, taxonomic number
        local host=\$(echo "\${info}" | awk -F'"' '/\\/host/ {print \$2}' | head -n 1)
        local tax=\$(echo "\${info}" | awk '/\\/db_xref/ { match(\$0, /taxon:([0-9]+)/, tax_id); print tax_id[1] }' | head -n 1)

        #put NA if any of the fields are empty
        if [[ -z "\${host}" ]]; then
            host="NA"
        else
            host=\$(printf "%s" "\$host" | tr -d '\\n')
        fi

        if [[ -z "\${tax}" ]]; then
            tax="NA"
        else
            tax=\$(printf "%s" "\$tax" | tr -d '\\n')
        fi

        #print output
        echo -e "\${contig}\\t\${col}\\t\${rest}\\t\${tax}\\t\${host}" >>\${output}

    }

    if [[ ! -s ${txt} || \$(grep -cv '^[[:space:]]*\$' ${txt}) -eq 0 ]]; then
            echo > "${name}_blastn_metadata2.tsv"
    else
        while IFS=\$'\\t' read -r col1 col2 rest;do
            tmpfile=\$(mktemp)
            get_meta "\${col1}" "\${col2}" "\${rest}" "\$tmpfile"
            cat "\$tmpfile" >> "${name}_blastn_metadata2.tsv"
            rm "\$tmpfile"
        done < "${txt}"
    fi
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fetch_metadata_2: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch _blastn_metadata2.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fetch_metadata_2: "1.0.0"
    END_VERSIONS
    """
}