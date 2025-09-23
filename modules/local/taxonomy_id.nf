process TAXONOMY_ID {

    tag "$meta.id"
    conda 'bioconda::curl'

    input:
    tuple val(meta), path('*.tsv')
    tuple val(meta), path('*.tsv')

    output:
    tuple val(meta), path('*.tsv')  , emit: final_accessions_tsv
    tuple val(meta), path('*.tsv')  , emit: acc_tax_id_tsv
    path "versions.yml"             , emit: versions

    script:
    def rvdb_final_acc = task.ext.rvdb_final_acc ?: ""
    def ncbi_final_acc = task.ext.ncbi_final_acc ?: ""
    def final_accessions_tsv = task.ext.final_accessions_tsv ?: ""
    def output_tsv = task.ext.output_tsv ?: ""
    """
    
    
    output_tsv="acc_tax_id.tsv"

    #combine rvdb_final_accessions.tsv and ncbi_final_accessions.tsv
    if [[ -s "${rvdb_final_acc}" && -s "${ncbi_final_acc}" ]];then
        cat "${rvdb_final_acc}" "${ncbi_final_acc}" > "${final_accessions_tsv}"

    #if only rvdb accessions file exists
    elif [[ -s "${rvdb_final_acc}" ]]; then
        cp "${rvdb_final_acc}" "${final_accessions_tsv}"

    #if only ncbi accessions file exists
    elif [[ -s "${ncbi_final_acc}" ]]; then
        cp "${ncbi_final_acc}" "${final_accessions_tsv}"
    
    #if neither accessions files exists
    else
        echo -e "Accessions file "${final_accessions_tsv}" not found."
        exit 1
    fi

    #sort and deduplicate acc_ids.txt
    sort -u "${final_accessions_tsv}" -o "${final_accessions_tsv}"

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
    done < "${final_accessions_tsv}"

    """

    stub:
    def final_accessions_tsv = task.ext.final_accessions_tsv ?: ""
    def output_tsv = task.ext.output_tsv ?: ""
    """
    touch ${final_accessions_tsv}
    touch ${output_tsv}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id: \$(echo \$(taxonomy_id -v 2>&1) | sed 's/TAXONOMY_ID v//')
    END_VERSIONS

    """
}
