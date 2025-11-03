process CONTIG_FILTER_2 {
    tag "${meta.id}"
    label 'process_low'

    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/67f4c80bd6c6/wave/build:contig_filter--f8e5cec565adc43e"

    input:
    tuple val(meta), path(tsv)
    
    output:
    tuple val(meta), path('*_viral_contigs_metadata.tsv')  , emit: tsv
    path "versions.yml"             , emit: versions
    
    script:
    def prefix = "${meta.id}"
    """
    #contig filtering according to kingdom viruses
    #extract contig matches that are part of viruses
    while IFS=\$'\\t' read -r -a fields; do
        if [[ "\${fields[11]}" == *Viruses* ]]; then
            printf "%s\\t" "\${fields[@]}" >> "${prefix}_viral_contigs_metadata.tsv"
            echo >> "${prefix}_viral_contigs_metadata.tsv"
        fi
    done < "${tsv}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        contig_filter: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch viral_contigs_metadata.tsv
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        contig_filter: "1.0.0"
    END_VERSIONS
    """
}