process SPLITTER{
    tag "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path("*.txt"), emit: txt
    path "versions.yml"             , emit: versions

    script:
    """
    awk -F'\\t' '{print \$3}' "${tsv}" > "${meta.id}_acc.tsv"
    sort -u "${meta.id}_acc.tsv" > "${meta.id}_acc_ids.tsv"
    split -e -l 100 "${meta.id}_acc_ids.tsv" ${meta.id}_acc_ids_
    for file in *; do
        if [[ "\${file}" == *.tsv ]]; then
            continue
        else
            tr '\\n' ',' < "\${file}" | sed 's/,\$/\\n/' > "\${file}.txt"
        fi
    done
    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        splitter: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch sample_merged.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        splitter: "1.0.0"
    END_VERSIONS
    """
}