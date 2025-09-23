process CONTIG_FILTER {
    
    input:
    tuple val(meta), path("*.tsv")
    
    output:
    tuple val(meta), path("*.tsv")  , emit: viral_contigs_metadata
    path "versions.yml"             , emit: versions
    
    script:
    //how does lineage file here link to the input file
    //should these files be allowed the option of empty
    def lineage_file = task.ext.lineage_file ?: ''
    def viral_contigs_metadata = task.ext.viral_contigs_metadata ?: ''
    """
    #contig filtering according to kingdom viruses
    #extract contig matches that are part of viruses
    while IFS=$'\\t' read -r col1 col2 col3 col4 rest; do
        if [[ \${col4} == *Virus* ]]; then
            echo -e "\${col1}\\t${col2}\\t${col4}\\t${rest}" >> "${viral_contigs_metadata}"
        fi
    done < ${lineage_file}
    """

    stub:
    def lineage_file = task.ext.lineage_file ?: ''
    def viral_contigs_metadata = task.ext.viral_contigs_metadata ?: ''
    """
    touch ${viral_contigs_metadata}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        contig_filter: \$(echo \$(contig_filter -v 2>&1) | sed 's/CONTIG_FILTER v//')
    END_VERSIONS


    """
}