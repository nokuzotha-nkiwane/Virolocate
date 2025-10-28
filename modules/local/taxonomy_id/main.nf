process TAXONOMY_ID {
    tag "${meta.id}"
    maxForks 3
    label 'process_long'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/curl:8.16.0--0f923aab65c12492' :
        'community.wave.seqera.io/library/curl:8.16.0--6a09e3d33a7b6391' }"


    input:
    tuple val(meta), path(txt)


    output:
    tuple val(meta), path('*_final_accessions.tsv')  , emit: tsv
    path "versions.yml"             , emit: versions

    script:
    def name = txt.getBaseName()
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
        local info=\$(curl -N -# -L --retry 5 --retry-delay 5 --max-time 15 --connect-timeout 10 \${url1})

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
        cat "\$tmpfile" >> "${name}_final_accessions.tsv"
        rm "\$tmpfile"

    done < ${txt}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id: "1.0.0"
    END_VERSIONS
    """

    stub:

    """
    touch _final_accessions.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id: "1.0.0"
    END_VERSIONS

    """
}
