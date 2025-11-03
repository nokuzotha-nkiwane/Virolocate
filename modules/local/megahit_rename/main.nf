process MEGAHIT_RENAME {
    tag "$meta.id"
    label 'process_low'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/cb/cb3804ff1e384f1d12ce6b1063a95e84b155b784d9287e44d431972593e61f98/data' :
        'community.wave.seqera.io/library/pigz:2.8--79421657784d0869' }"

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