process MAKE_BLAST_FASTA {
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/f0df4f3f12cd/wave/build:make_blast_fasta--b4fc6a3e025d3533"

    input:
    tuple val(meta), path(txt)

    output:
    tuple val(meta) , path('*.fasta')   , emit: blast_contigs_fasta
    path "versions.yml"             , emit: versions

    script:
    def kfinal_contigs = task.ext.kfinal_contigs 
    def viral_contig_list = task.ext.viral_contig_list
    def blast_contigs_fasta = task.ext.blast_contigs_fasta

    """
    #find the contig matches in the final.contigs.fa file

    while read -r hit; do
        awk -v contig=">\${hit} " '
            index(\$0, contig) == 1 {print; ON=1; next}
            ON && /^>/ {exit}
            ON {print}
        ' ${kfinal_contigs} >> "${blast_contigs_fasta}"

        #progress check
        echo "Sequence for \${hit} found"
    done < "${viral_contig_list}"
    """

    stub:
    def blast_contigs_fasta = task.ext.blast_contigs_fasta 
    """
    touch blastn_contigs_fasta.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        make_blast_fasta: "1.0.0"
    END_VERSIONS
    """
}