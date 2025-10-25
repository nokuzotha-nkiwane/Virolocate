process MERGER_PROCESSING {
    label 'process_low'

    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/15d0d9436d7f/wave/build:ncbi_processing--b61e3e84fb1e5c3f"

    input:
    path(tsv)

    output:
    path('*.tsv')                    , emit: tsv
    path "versions.yml"             , emit: versions


    script:
    """
    cat ${tsv} > "metadata.tsv"


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger_processing: "1.0.0"
    END_VERSIONS
    """
    
    stub:
    
    """
    touch final_blast_contigs.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger_processing: "1.0.0"
    END_VERSIONS

    """
}
