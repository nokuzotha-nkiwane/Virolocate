process SPLITTER{
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path("${meta.id}_*.txt"), emit: txt
    path "versions.yml"             , emit: versions

    script:
    """
    split -n l/${task.cpus} "${meta.id}_merged.tsv" ${meta.id}_
    rm "${meta.id}_merged.tsv"
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