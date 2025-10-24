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
    split -n l/${task.cpus} "${txt}" ${meta.id}_
    rm "${txt}"
    for file in ${meta.id}_*; do
        mv "\${file}" "\${file}.txt"
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