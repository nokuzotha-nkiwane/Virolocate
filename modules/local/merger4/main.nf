process MERGER4 {
    tag "${meta.id}"
    label 'process_long'
    label 'process_high'

    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/cf2847dec15c/wave/build:taxonomy_id--5d733d140ee5728f"

    input:
    tuple val(meta), path(lst), path(gbs) 


    output:
    tuple val(meta), path('*_tax.tsl')  , emit: tsl
    path "versions.yml"             , emit: versions

    script:
    
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

        tax=\$(grep -oE 'taxon:[0-9]+' "\${tmpfile1}" | head -n 1 | cut -d: -f2 )

        if [[ -z "\${tax}" ]]; then
            tax="NA"

        else
            tax=\$(printf "%s" "\$tax" | tr -d '\\n')
        fi

        base_name=\$(basename "${lst}" .lst)
        tmpfile2=\$(mktemp "\${tmp_dir2}/file_XXXXXXX")
        echo -e "\${col1}\\t\${tax}" >> "\${tmpfile2}"
       
        cat "\${tmpfile2}" >> "\${base_name}_tax.tsl"
        rm "\${tmpfile1}" "\${tmpfile2}"

    done < "${lst}"
    rm -rf "\${tmp_dir1}" "\${tmp_dir2}"
    
            
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id_check: "1.0.0"
    END_VERSIONS
    """

    stub:

    """
    touch _check.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id_check: "1.0.0"
    END_VERSIONS

    """
}
