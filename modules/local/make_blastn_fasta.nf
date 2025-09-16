process MAKE_BLASTN_FASTA {

    input:

    output:

    script:      
    """
    #find the contig matches in the final.contigs.fa file

    while read -r hit; do
        awk -v contig=">${hit} " '
            index($0, contig) == 1 {print; ON=1; next}
            ON && /^>/ {exit}
            ON {print}
        ' ${params.fin_fasta} >> ${params.output_fa}

        #progress check
        echo "Sequence for ${hit} found"
    done < ${params.u_match_out}
    """

    stub:
    """

    """
}