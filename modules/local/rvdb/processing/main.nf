process RVDB_PROCESSING {
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/935142d6c1b1/wave/build:rvdb_processing--a737d7798a59a0c3"

    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path('acc_tax_id.tsv ')  , emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    #take nucleotide acc_id from diamond output file
    
    if [[ -f "${tsv}" ]];then
        while IFS=\$'\\t' read -r col1 col2 col3 col4 rest; do
            if [[ -n "\${col1}" ]] && [[ "\${col1}" != "#"* ]]; then
                acc_id=\$(echo "\${col3}" | cut -d "|" -f3)
                name=\$(echo "\${col4}" | cut -d "|" -f6)
                echo -e "\${col1}\\t\${col2}\\t\${acc_id}\\t\${name}\\t\${rest}" >> acc_tax_id.tsv 
            fi
        done < "${tsv}" 
        

    #if directory or files empty
    else
        echo "RVDB directory does not exist or is empty. Searching for NCBI directory."
        echo "# No RVDB data processed" > acc_tax_id.tsv 
    fi
    

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
