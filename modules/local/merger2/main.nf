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
    tmp_dir=$(mktemp -d)
    batch_size=100     # adjust: number of records per batch
    count=0
    batch_num=0
    batch_file="\$tmp_dir/batch_${batch_num}.tmp"

    while IFS=$'\t' read -r col1 col2 col3 rest; do
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

        info=$(awk -v acc="\${col3}" '
            BEGIN {in_block=0; matched=0}
            /^LOCUS/ { block=""; in_block=1 }
            in_block { block = block \$0 "\n" }
            /^\\/\\// {
                if (block ~ acc || block ~ ("VERSION[[:space:]]+" acc) || block ~ ("ACCESSION[[:space:]]+" acc)) {
                    print block; matched=1
                }
                in_block=0; block=""
            }
            END { if (matched==0) exit 1 }
        ' "\${found_file}")

        tax=$(awk '
            /db_xref="taxon:[0-9]+"/ { match(\$0,/taxon:([0-9]+)/,a); if(a[1]!=""){print a[1]; exit} }
        ' <<< "\$info")

        [[ -z "\$tax" ]] && tax="NA"

        printf "%s\\t%s\\t%s\\t%s\\t%s\\n" "\${col1}" "\${col2}" "\${col3}" "\${rest}" "\${tax}" >> "\$batch_file}"

        ((count++))
        if (( count % batch_size == 0 )); then
            batch_num=$((batch_num + 1))
            batch_file="\$tmp_dir/batch_\${batch_num}.tmp"
        fi

    done < "${tsv}"

    # merge batches atomically
    cat "\${tmp_dir}"/*.tmp > "${meta.id}_tax.tsv"
    rm -rf "\${tmp_dir}"
    sync

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