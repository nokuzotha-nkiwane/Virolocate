process MERGER{
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(ncbi_tsv), path(rvdb_tsv)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    cat "${ncbi_tsv}" > "${meta.id}_merged.tsv"
    awk 'NF' "${rvdb_tsv}" >> "${meta.id}_merged.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch sample_merged.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger: "1.0.0"
    END_VERSIONS
    """
}