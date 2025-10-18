process SPLITTER{
    tag "${meta.id}"

    input:
    tuple val(meta), path(ncbi_tsv), path(rvdb_tsv)

    output:
    tuple val(meta), path("${meta.id}_*"), emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    cat "${ncbi_tsv}" > "${meta.id}_merged.tsv"
    cat "${rvdb_tsv}" >> "${meta.id}_merged.tsv"

    split -n l/${task.cpus} "${meta.id}_merged.tsv" ${meta.id}_

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