process MERGER2 {
    tag "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(tsv), path(gbs)


    output:
    tuple val(meta), path("*_tax.tsv"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    tmp_dir1=\$(mktemp -d)
    tmp_dir2=\$(mktemp -d)
    while IFS=\$'\\t' read -r col1 col2 col3 rest; do
        found_file=""
        for gb in ${gbs}; do
            if grep -qE "VERSION[[:space:]]+\${col3}" "\${gb}" || grep -qE "ACCESSION[[:space:]]+\${col3}" "\${gb}"; then
                found_file="\${gb}"
                break
            fi
        done

        if [[ -z "\${found_file}" ]]; then
            echo "\${col3} not found" >&2
            continue
        fi

       
        tmpfile1=\$(mktemp "\${tmp_dir1}/tmpfile_\${col3}.tmp")
        awk -v acc="\${col3}" -v file="\${tmpfile1}" '
            BEGIN {in_block=0; matched=0}
            /^LOCUS/ { block=""; in_block=1 }
            in_block { block = block \$0 "\\n" }
            /^\\/\\// {
                if (block ~ acc || block ~ ("VERSION[[:space:]]+" acc) || block ~ ("ACCESSION[[:space:]]+" acc)) {
                    print block > file
                    matched=1
                }
                in_block=0; block=""
            }
            END { if (matched==0) exit 1 }
        ' "\${found_file}" || continue

        tax=\$(grep -oE 'taxon:[0-9]+' "\${tmpfile1}" | head -n 1 | cut -d: -f2 )

        if [[ -z "\${tax}" ]]; then
            tax="NA"

        else
            tax=\$(printf "%s" "\$tax" | tr -d '\\n')
        fi

        
        tmpfile2=\$(mktemp "\${tmp_dir2}/file_XXXXXXX")
        echo -e "\${col1}\\t\${col2}\\t\${col3}\\t\${rest}\\t\${tax}" >> "\${tmpfile2}"
       
        cat "\${tmpfile2}" >> "${meta.id}_tax.tsv"
        rm "\${tmpfile1}" "\${tmpfile2}"

    done < "${tsv}"
    rm -rf "\${tmp_dir1}" "\${tmp_dir2}"
    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger2: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch sample_tax.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger2: "1.0.0"
    END_VERSIONS
    """
}