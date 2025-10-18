process MAKE_BLAST_FASTA {
    tag "${meta.id}"
    label 'process_medium'

    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/f0df4f3f12cd/wave/build:make_blast_fasta--b4fc6a3e025d3533"

    input:
    tuple val(meta), path(txt), path(contigs)


    output:
    tuple val(meta) , path('*_blast_contigs.fasta'), emit: fasta
    path "versions.yml"             , emit: versions

    script:
    def prefix = "${meta.id}"
    def is_compressed = contigs.getExtension() == "gz" ? true : false
    def contig_file = is_compressed ? contigs.getBaseName() : contigs
    """
    if [ "${is_compressed}" == "true" ]; then
        gzip -c -d ${contigs} > ${contig_file}
    fi

    while read -r hit; do
    if grep -qF ">\${hit}" "${contig_file}"; then
        awk -v contig=">\${hit}" '
            \$0 ~ ("^"contig) {print; ON=1; next}
            ON && /^>/ {exit}
            ON {print}
        ' ${contig_file} >> "${prefix}_blast_contigs.fasta"
    fi

    #progress check
    echo "Sequence for \${hit} found"
    done < "${txt}"

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