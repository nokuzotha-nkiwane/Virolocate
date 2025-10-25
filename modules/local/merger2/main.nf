process MERGER2 {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(tsvs), path(tsvs2)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    cat ${tsvs} > "${meta.id}_collect.tsv"
    awk -F'\\t' '\$9 != "NA"' "${meta.id}_collect.tsv" > "${meta.id}_collect2.tsv"
    cat ${tsvs2} >>  "${meta.id}_collect2.tsv"
    awk 'NF' "${meta.id}_collect.tsv" > "${meta.id}_collected.tsv"


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