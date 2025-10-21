process MERGER2 {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(tsvs), path(tsvs2)

    output:
    tuple val(meta), path("${meta.id}_collected.tsv"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    awk 'NF' "${tsvs}" > "${meta.id}_collected.tsv"
    awk 'NF' "${tsvs2}" >> "${meta.id}_collected.tsv"

    if [[ -z]]

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