process FASTA_SPLIT {
    tag "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}_*.fasta"), emit: fasta
    path "versions.yml"             , emit: versions

    script:
    """
    split -n l/${task.cpus} "${fasta}" ${meta.id}_
    rm "${fasta}"
    for file in ${meta.id}_*; do
        if [[ \$(grep -cv '^[[:space:]]*\$' "\${file}") -eq 0 ]]; then
            rm "\${file}"
        else
            mv "\${file}" "\${file}.fasta"
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fasta_split: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch final_m.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fasta_split: "1.0.0"
    END_VERSIONS
    """
}