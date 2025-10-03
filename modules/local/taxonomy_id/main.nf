process TAXONOMY_ID {
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/cf2847dec15c/wave/build:taxonomy_id--5d733d140ee5728f"

    input:
    tuple val(meta), path(ncbi_tsv) 
    tuple val(meta), path(rvdb_tsv)

    output:
    tuple val(meta), path('final_accessions.txt')  , emit: final_accessions_txt
    tuple val(meta), path('acc_tax_id.tsv')  , emit: acc_tax_id_tsv
    path "versions.yml"             , emit: versions

    script:
    def final_accessions_txt = task.ext.final_accessions_txt ?: ""
    def acc_tax_id_tsv = task.ext.acc_tax_id_tsv ?: ""
    """

    #combine rvdb_final_accessions.tsv and ncbi_final_accessions.tsv
    if [[ -s "${rvdb_tsv}" && -s "${ncbi_tsv}" ]];then
        cat "${rvdb_tsv}" "${ncbi_tsv}" > "${final_accessions_txt}"

    #if only rvdb accessions file exists
    elif [[ -s "${rvdb_tsv}" ]]; then
        cp "${rvdb_tsv}" "${final_accessions_txt}"

    #if only ncbi accessions file exists
    elif [[ -s "${ncbi_tsv}" ]]; then
        cp "${ncbi_tsv}" "${final_accessions_txt}"

    #if neither accessions files exists
    else
        echo -e "Accessions file "${final_accessions_txt}" not found."
        exit 1
    fi

    #sort and deduplicate acc_ids.txt
    sort -u "${final_accessions_txt}" -o "${final_accessions_txt}"

    #function to get metadata from eutils
    get_meta() {

        local contig=\$1
        local length=\$2
        local acc_id=\$3
        local output=\$4

        #progress check
        echo "Fetching metadata for "\${acc_id}"
        #print ncbi page of protein accession and parse taxonomic id for use in taxonkit for lineage
        local url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=\${acc_id}&rettype=gb&retmode=text"
        local info=\$(curl -N -# \${url1})

        #taxonomic number
        local tax=\$(echo "\${info}" | awk '/\\/db_xref/ { match(\$0, /taxon:([0-9]+)/, tax_id); print tax_id[1] }')

        if [[ -z "\${tax}" ]]; then
            tax="NA"
        fi

        #print output
        echo -e "\${contig}\\t\${length}\\t\${acc_id}\\t\${tax}" >>\${output}

    }

    while IFS=\$'\\t' read -r col1 col2 col3 rest;do
        echo "[\${col3}]"
        get_meta "\${col1}" "\${col2}" "\${col3}" "${output_tsv}"
    done < "${final_accessions_txt}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id: "1.0.0"
    END_VERSIONS
    """

    stub:
    def final_accessions_txt = task.ext.final_accessions_txt ?: ""
    def output_tsv = task.ext.output_tsv ?: ""
    """
    touch final_accessions.txt
    touch acc_tax_id.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id: "1.0.0"
    END_VERSIONS

    """
}
