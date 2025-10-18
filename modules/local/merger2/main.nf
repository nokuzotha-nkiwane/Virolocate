process MERGER2 {
    tag "${meta.id}"

    input:
    tuple val(meta), path(tsvs)

    output:
    tuple val(meta), path("${meta.id}_collected.tsv"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    cat ${tsvs.join(' ')} > "${meta.id}_collected.tsv"

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