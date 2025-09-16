process CONTIG_FILTER {

    input:
    path "acc_tax_id.tsv"

    output:
    path "blastn_contigs.fasta", emit: blastn_contigs_fasta

    script:
    """
    blastn_contigs_fasta="blastn_contigs.fasta"
    #contig filtering according to kingdom viruses
    #extract contig matches that are part of viruses
    while IFS=$'\t' read -r col1 col2 col3 col4 rest; do
        if [[ ${col4} == *Virus* ]]; then
            echo -e "${col1}\t${col2}\t${col4}\t${rest}" >> ${params.viral_contigs}
        fi
    done < ${lineage_out}
    """

    stub:
    """

    """
}