process MEGAHIT_RENAME {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta) , path(fasta)

    output:
    tuple val(meta) , path('*_renamed.contigs.fa.gz'), emit: contigs
    path "versions.yml"                              , emit: versions

    script: 
    def prefix = "${meta.id}"
    def output1 = "${prefix}_renamed.contigs.fa"
    def is_compressed = fasta.getExtension() == "gz" ? true : false
    def fasta_name = is_compressed ? fasta.getBaseName() : fasta
    """
    if [ "${is_compressed}" == "true" ]; then
        gzip -c -d ${fasta} > ${fasta_name}
    fi

    awk -v prefix="${meta.id}_" '
        /^>/ {\$0=">" prefix substr(\$0,2)} {print}
    ' ${fasta_name} > ${output1}

    pigz ${output1}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        megahit_rename: "1.0.0"
    END_VERSIONS
    """
    
    stub:
    """
    touch 1_renamed.contigs.fa.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        megahit_rename: "1.0.0"
    END_VERSIONS
    """
}