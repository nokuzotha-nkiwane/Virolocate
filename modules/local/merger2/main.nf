process MERGER2 {
    tag "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(tsv), path(gbs)


    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    while IFS=\$'\\t' read -r col1 col2 rest; do

    
        found_file=""
        for gb in ${gbs}; do
            if grep -qE "VERSION[[:space:]]+${col2}" "${gb}" || grep -qE "ACCESSION[[:space:]]+\${col2}" "${gb}"; then
                found_file="\${gb}"
                break
            fi
        done
        if [[ -z "$found_file" ]]; then
            echo "${col2} not found" >&2
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
        ' "\$found_file")

        host=\$(echo "\${info}" | awk -F'"' '/\\/host/ {print \$2}' | head -n 1)
        geo_loc_name=\$(echo "\${info}" | awk -F'"' '/\\/geo_loc_name/ {print \$2}' | head -n 1)
        date=\$(echo "\${info}" | awk -F'"' '/\\/collection_date/ {print \$2}' | head -n 1)
        gene=\$(echo "\${info}" | awk -F'"' '/\\/coded_by/ {print \$2}' | head -n 1)
        product=\$(echo "\${info}" | awk -F'"' '/\\/product/ {print \$2}' | head -n 1)
        tax=\$(echo "\${info}" | awk '/\\/db_xref/ { match(\$0, /taxon:([0-9]+)/, tax_id); print tax_id[1] }' | head -n 1)

        for var in host source geo_loc_name date gene product tax; do
            [[ -z "\${!var:-}" ]] && declare "\$var"="NA"
        done

        echo -e "\${col1}\\t\${col2}\\t\${rest}\\t\${tax}\\t\${host}\\t\${gene}\\t\${product}\\t\${geo_loc_name}\\t\${date}" >> ${meta.id}_merged.tsv

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