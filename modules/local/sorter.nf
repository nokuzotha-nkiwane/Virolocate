process CONTIG_UNIQUE_SORTER {

    input:

    output:

    script: 
    """
    #get unique contig matches
    cat ${viral_contigs} | awk '{print $1}' > ${params.u_match_out}
    sort -u ${params.u_match_out} -o ${params.u_match_out}
    """


    stub:
    """

    """
}