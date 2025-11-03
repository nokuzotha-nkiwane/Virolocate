process SPLITTER_2{
    tag "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(txt)

    output:
    tuple val(meta), path('*.txt'), emit: txt
    tuple val(meta), path("*.lst"), emit: lst
    path "versions.yml"             , emit: versions

    script:
    """
    awk -F'\\t' '{print \$2}' "${txt}" | awk -F'|' '{print \$4}' > "${meta.id}_acc.tsv"
    sort -u "${meta.id}_acc.tsv" > "${meta.id}_acc_ids.tsv"
    split -e -l 100 "${meta.id}_acc_ids.tsv" ${meta.id}_split
    rm "${txt}"
    for file in ${meta.id}_split*; do
        cp "\${file}" "\${file}.lst"
        tr '\\n' ',' < "\${file}" | sed 's/,\$/\\n/' > "\${file}.txt"  
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