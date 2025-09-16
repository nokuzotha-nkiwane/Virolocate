process MAKE_BLASTN_FASTA {

    input:
    path "viral_contig_list.txt"

    output:
    path "blastn_contigs.fasta", emit: blastn_contigs_fasta

    script:      
    """
    viral_contig_list = "viral_contig_list.txt"
    viral_contig_list = "blastn_contigs.fasta"
    #find the contig matches in the final.contigs.fa file

    while read -r hit; do
        awk -v contig=">${hit} " '
            index($0, contig) == 1 {print; ON=1; next}
            ON && /^>/ {exit}
            ON {print}
        ' ${kfinal_contigs} >> "\${viral_contig_list}"

        #progress check
        echo "Sequence for ${hit} found"
    done < "\${viral_contig_list}"
    """

    stub:
    """

    """
}