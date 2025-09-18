process MAKE_BLASTN_FASTA {

    input:
    tuple val(meta), path("*.txt")

    output:
    tuple val(meta) , path(fasta), emit: blastn_contigs_fasta

    script:
    def kfinal_contigs = task.ext.kfinal_contigs ?: ''
    def viral_contig_list = task.ext.viral_contig_list ?: ''
    def blastn_contigs_fasta = task.ext.blastn_contigs_fasta ?: ''

    """
    #find the contig matches in the final.contigs.fa file

    while read -r hit; do
        awk -v contig=">${hit} " '
            index($0, contig) == 1 {print; ON=1; next}
            ON && /^>/ {exit}
            ON {print}
        ' ${kfinal_contigs} >> "${blastn_contigs_fasta}"

        #progress check
        echo "Sequence for ${hit} found"
    done < "${viral_contig_list}"
    """

    stub:
    def blastn_contigs_fasta = task.ext.blastn_contigs_fasta ?: ''
    """
    touch ${blastn_contigs_fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        make_blastn_fasta: \$(echo \$(make_blastn_fasta -v 2>&1) | sed 's/MAKE_BLASTN_FASTA v//')
    END_VERSIONS
    """
}