process MERGER3 {
    tag "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(tsvs), path(tsvs2)


    output:
    tuple val(meta), path("*_tax.tsv"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    awk -F'\\t' '\$9 != "NA"' ${tsvs} > ${meta.id}_tax.tsv
    awk 'NF' ${tsvs2} >> ${meta.id}_tax.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger3: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch sample_tax.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger3: "1.0.0"
    END_VERSIONS
    """
}