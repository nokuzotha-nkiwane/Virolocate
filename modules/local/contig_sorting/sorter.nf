process CONTIG_UNIQUE_SORTER {
    conda "${moduleDir}/environment.yml"
    container "wave.seqera.io/wt/3b0bb1363235/wave/build:contig_sorter--c494d63b9df9105e"

    input:
    tuple val(meta), path("*.tsv")

    output:
    tuple val(meta), path("*.txt")  , emit:viral_contig_list
    path "versions.yml"             , emit: versions

    script: 
    def viral_contigs_metadata = task.ext.viral_contigs_metadata ?: ''
    def viral_contig_list = task.ext.viral_contig_list ?: ''
    """
    #get unique contig matches
    awk '{print \$1}' "${viral_contigs_metadata}"  | sort -u  -o ${viral_contig_list}
    """

    stub:
    """
    touch "${viral_contig_list}"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        contig_sorter: \$(contig_sorter -v 2>&1 | sed 's/CONTIG_SORTER v//')
    END_VERSIONS

    """
}