process CONTIG_FILTER {
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/67f4c80bd6c6/wave/build:contig_filter--f8e5cec565adc43e"

    input:
    tuple val(meta), path(tsv)
    
    output:
    tuple val(meta), path("*.tsv")  , emit: viral_contigs_metadata
    path "versions.yml"             , emit: versions
    
    script:
    //how does lineage file here link to the input file 
    //should these files be allowed the option of empty
    def viral_contigs_metadata = task.ext.viral_contigs_metadata 
    """
    #contig filtering according to kingdom viruses
    #extract contig matches that are part of viruses
    while IFS=\$'\\t' read -r col1 col2 col3 col4 rest; do
        if [[ \${col4} == *Virus* ]]; then
            echo -e "\${col1}\\t${col2}\\t${col4}\\t${rest}" >> "${viral_contigs_metadata}"
        fi
    done < ${tsv}
    """

    stub:

    def viral_contigs_metadata = task.ext.viral_contigs_metadata 
    """
    touch viral_contigs_metadata.tsv
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        contig_filter: "1.0.0"
    END_VERSIONS


    """
}