process TAXONOMY_ID {
    tag "${meta.id}"
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/cf2847dec15c/wave/build:taxonomy_id--5d733d140ee5728f"

    input:
    tuple val(meta), path(tsv) 


    output:
    tuple val(meta), path('*_final_accessions.tsv')  , emit: tsv
    path "versions.yml"             , emit: versions

    script:
    def prefix = "${meta.id}"
    """

    #function to get metadata from eutils
    get_meta() {

        local contig=\$1
        local length=\$2
        local acc_id=\$3
        local rest=\$4
        local output=\$5

        #progress check
        echo "Fetching metadata for "\${acc_id}""
        #print ncbi page of protein accession and parse taxonomic id for use in taxonkit for lineage
        local url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=\${acc_id}&rettype=gb&retmode=text"
        local info=\$(curl -N -# -L --retry 3 --connect-timeout 5 \${url1})

        #taxonomic number
        local tax=\$(echo "\${info}" | awk '/\\/db_xref/ { match(\$0, /taxon:([0-9]+)/, tax_id); print tax_id[1] }')

        if [[ -z "\${tax}" ]]; then
            tax="NA"

        else
            tax=\$(printf "%s" "\$tax" | tr -d '\\n')
        fi

        #print output
        echo -e "\${contig}\\t\${length}\\t\${acc_id}\\t\${rest}\\t\${tax}" >>\${output}
        sleep 0.34

    }

    while IFS=\$'\\t' read -r col1 col2 col3 rest;do
        echo "[\${col3}]"
        tmpfile=\$(mktemp)
        get_meta "\${col1}" "\${col2}" "\${col3}" "\${rest}" "\$tmpfile"
        cat "\$tmpfile" >> "${prefix}_final_accessions.tsv"
        rm "\$tmpfile"

    done < ${tsv}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id: "1.0.0"
    END_VERSIONS
    """

    stub:

    """
    touch final_accessions.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id: "1.0.0"
    END_VERSIONS

    """
}
