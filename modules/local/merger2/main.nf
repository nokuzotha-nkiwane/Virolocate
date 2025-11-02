process MERGER2 {
    tag "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(lst), path(gbs)


    output:
    tuple val(meta), path("*_tax.tsv"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    def name = lst.getBaseName()
    """
    tmp_dir1=\$(mktemp -d)
    tmp_dir2=\$(mktemp -d)
    while IFS=\$'\\t' read -r access; do
        found_file=""
        for gb in ${gbs}; do
            if grep -qE "VERSION[[:space:]]+\${access}" "\${gb}" || grep -qE "ACCESSION[[:space:]]+\${access}" "\${gb}"; then
                found_file="\${gb}"
                break
            fi
        done

        if [[ -z "\${found_file}" ]]; then
            echo "\${access} not found" >&2
            continue
        fi

       
        tmpfile1=\$(mktemp "\${tmp_dir1}/tmpfile_XXXXXXX.tmp")
        awk -v acc="\${access}" -v file="\${tmpfile1}" '
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

        taxonomy_block=\$(awk '/ORGANISM/,/REFERENCE/' "\${tmpfile1}")
        taxonomy_block=\$(echo "\${taxonomy_block}" | grep -vE 'ORGANISM|REFERENCE')
        taxonomy_block=\$(echo "\${taxonomy_block}" | tr -d '\\n' |  tr ';' '\\t')

        if [[ -z "\${taxonomy_block}" ]]; then
            taxonomy_block="NA"

        else
            taxonomy_block=\$(printf "%s" "\${taxonomy_block}" | tr -d '\\n')
        fi

        
        tmpfile2=\$(mktemp "\${tmp_dir2}/file_XXXXXXX")
        echo -e "\${access}\\t\${taxonomy_block}" >> "\${tmpfile2}"
       
        cat "\${tmpfile2}" >> "${name}_tax.tsv"
        rm "\${tmpfile1}" "\${tmpfile2}"

    done < "${lst}"
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