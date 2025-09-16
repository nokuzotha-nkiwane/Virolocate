process CONTIG_UNIQUE_SORTER {

    input:
    ptuple val(meta), path("*.tsv")

    output:
    tuple val(meta), path("*.txt"), emit:viral_contig_list

    script: 
    """
    viral_contigs_metadata = "viral_contigs.tsv"
    viral_contig_list = "viral_contig_list.txt"
    #get unique contig matches
    awk '{print \$1}' "\${viral_contigs_metadata}"  | sort -u  -o ${viral_contig_list}
    """

    stub:
    """

    """
}