process SPLITTER_2{
    tag "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(txt)

    output:
    tuple val(meta), path("${meta.id}_*.txt"), emit: txt
    path "versions.yml"             , emit: versions

    script:
    """
    awk -F'\\t' '{print \$2}' "${tsv}" | awk -F'|' '{print \$4} > "${meta.id}_acc.tsv"
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
        splitter_2: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch final_m.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        splitter_2: "1.0.0"
    END_VERSIONS
    """
}