process CONTIG_UNIQUE_SORTER {

    input:
    path "viral_contig_metadata.tsv"

    output:
    path "viral_contig_list.txt"

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