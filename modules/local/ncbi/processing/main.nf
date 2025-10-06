process DIAMOND_PROCESSING {
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/15d0d9436d7f/wave/build:ncbi_processing--b61e3e84fb1e5c3f"

    input:
    path(tsv)

    output:
    path('final_acc.tsv')  , emit: tsv
    path "versions.yml"             , emit: versions


    script:
    """
    cat ${tsv} >> final_acc.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncbi_processing: "1.0.0"
    END_VERSIONS
    """
    
    stub:
    
    """
    touch final_acc.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncbi_processing: "1.0.0"
    END_VERSIONS

    """
}
