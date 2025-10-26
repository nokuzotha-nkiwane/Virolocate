process MERGER2 {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(tsv), path(gbs)


    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    while IFS=\$'\\t' read -r col1 col2 rest; do
    
        local file=\$(grep -lE "VERSION[[:space:]]+\${col2}" ${gbs} | head -n 1)
        if [[ -z "\$file" ]]; then 
            echo "\${col2}" not found" >&2 
            continue
        fi

        info=\$(awk -v acc="\${col2}" '
        BEGIN {found=0}
        /^VERSION[[:space:]]+/ {
            if (\$2 == acc) {found=1}
        }
        /^ACCESSION[[:space:]]+/ {
        if (!found && \$2 == acc) found=1
        }
        found {
            print
            if (/^\\/\\//) exit
        }
        ' "\$file")

        local host=\$(echo "\${info}" | awk -F'"' '/\\/host/ {print \$2}' | head -n 1)
        local geo_loc_name=\$(echo "\${info}" | awk -F'"' '/\\/geo_loc_name/ {print \$2}' | head -n 1)
        local date=\$(echo "\${info}" | awk -F'"' '/\\/collection_date/ {print \$2}' | head -n 1)
        local gene=\$(echo "\${info}" | awk -F'"' '/\\/coded_by/ {print \$2}' | head -n 1)
        local product=\$(echo "\${info}" | awk -F'"' '/\\/product/ {print \$2}' | head -n 1)
        local tax=\$(echo "\${info}" | awk '/\\/db_xref/ { match(\$0, /taxon:([0-9]+)/, tax_id); print tax_id[1] }' | head -n 1)

        for var in host source geo_loc_name date gene product tax; do
            [[ -z "\${!var:-}" ]] && declare "\$var"="NA"
        done

        echo -e "\${col1}\\t\${col2}\\t\${rest}\\t\${tax}\\t\${host}\\t\${gene}\\t\${product}\\t\${geo_loc_name}\\t\${date}" >> ${meta.id}.tsv

    done < ${tsv}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger2: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch sample_collected.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger2: "1.0.0"
    END_VERSIONS
    """
}