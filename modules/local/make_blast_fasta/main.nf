process MAKE_BLAST_FASTA {
    tag "${meta.id}"
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/f0df4f3f12cd/wave/build:make_blast_fasta--b4fc6a3e025d3533"

    input:
    tuple val(meta), path(txt)
    tuple val(meta), path(contigs)

    output:
    tuple val(meta) , path('final_blast_contigs.fasta')   , emit: fasta
    path "versions.yml"             , emit: versions

    script:
    def prefix = "${meta.id}"
    def is_compressed = contigs.getExtension() == "gz" ? true : false
    def contig_file = is_compressed ? contigs.getBaseName() : contigs
    """
    if [ "${is_compressed}" == "true" ]; then
        gzip -c -d ${contigs} > ${contig_file}
    fi
    

    #find the contig matches in the final.contigs.fa file
    while IFS=\$'\\t' read -r col1 col2 rest; do
        awk -v sample="\${col1}" -v contig=">\${col2}" '
            index(\$0, contig) == 1 {
            print ">" sample ":" substr(\$0, 2)
            ON = 1
            next
        }
        ON && /^>/ {exit}
        ON
        ' ${contig_file} >> "${prefix}_blast_contigs.fasta"

        #progress check
        echo "Sequence for \${col2} found"
    done < "${txt}"

    cat "${prefix}_blast_contigs.fasta" >> final_blast_contigs.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        make_blast_fasta: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch final_blast_contigs.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        make_blast_fasta: "1.0.0"
    END_VERSIONS
    """
}