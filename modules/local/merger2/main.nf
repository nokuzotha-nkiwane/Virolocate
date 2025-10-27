process MERGER2 {
    tag "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(tsv), path(gbs)


    output:
    tuple val(meta), path("*_merged.tsv"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    while IFS=\$'\\t' read -r col1 col2 col3 rest; do

    
        found_file=""
        for gb in ${gbs}; do
            if grep -qE "VERSION[[:space:]]+\${col3}" "\${gb}" || grep -qE "ACCESSION[[:space:]]+\${col3}" "\${gb}"; then
                found_file="\${gb}"
                break
            fi
        done
        if [[ -z "\$found_file" ]]; then
            echo "\${col2} not found" >&2
            continue
        fi

        info=\$(awk -v acc="\${col3}" '
            BEGIN {in_block=0; matched=0}
            /^LOCUS/ { block=""; in_block=1 }
            in_block { block = block \$0 "\\n" }
            /^\\/\\// {
                if (block ~ acc) {
                    print block
                    matched=1
                }
                in_block=0
                block=""
            }
            END {
                if (matched==0) exit 1
            }
        ' "\$found_file")

        
        tax=\$(awk '/taxon:[0-9]+/ { match(\$0, /taxon:([0-9]+)/, tax_id); if (tax_id[1]!="") { print tax_id[1]; exit }}' <<< "\${info}")
        
        if [[ -z "\${tax}" ]]; then
            tax="NA"
        else
            tax=\$(printf "%s" "\${tax}" | tr -d '\\n')
        fi

        echo -e "\${col1}\\t\${col2}\\t\${col3}\${rest}\\t\${tax}" >> ${meta.id}_merged.tsv

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