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
    split -n l/${task.cpus} "${tsv}" ${meta.id}_
    rm "${tsv}"
    for file in ${meta.id}_*; do
        mv "\${file}" "\${file}.txt"
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