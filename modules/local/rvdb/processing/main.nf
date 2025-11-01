process RVDB_PROCESSING {
    tag "${meta.id}"
    label 'process_low'

    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/935142d6c1b1/wave/build:rvdb_processing--a737d7798a59a0c3"

    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path('*_rvdb.tsv')  , emit: tsv
    path "versions.yml"             , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    #take nucleotide acc_id from diamond output file
    
    if [[ ! -s "${tsv}" || \$(grep -cv '^[[:space:]]*\$' "${tsv}") -eq 0]]; then
        echo "" > "${prefix}_rvdb.tsv"
    else
        # process the file line by line
        tmpfile="${prefix}.tsv.tmp"
        while IFS=\$'\\t' read -r col1 col2 col3 col4 rest; do
            if [[ -n "\${col1}" ]] && [[ "\${col1}" != "#"* ]]; then
                acc_id=\$(echo "\${col3}" | awk -F'|' '{print \$3}')
                name=\$(echo "\${col4}" | awk -F'|' '{print \$6}')
                echo -e "\${col1}\\t\${col2}\\t\${acc_id}\\t\${name}\\t\${rest}" >> "\${tmpfile}"
            fi
        done < "${tsv}"
        cat "\${tmpfile}" > "${prefix}_rvdb.tsv"
    fi

    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rvdb_processing: "1.0.0"
    END_VERSIONS

    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.rvdb.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rvdb_processing: "1.0.0"
    END_VERSIONS

    """
}
