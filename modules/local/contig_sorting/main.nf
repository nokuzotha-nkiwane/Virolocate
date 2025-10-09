process CONTIG_UNIQUE_SORTER {
    tag "${meta.id}"
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/3b0bb1363235/wave/build:contig_sorter--c494d63b9df9105e"

    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path("*_viral_contig_list.txt")  , emit: txt
    path "versions.yml"             , emit: versions

    script: 
    def prefix = "${meta.id}"
    """
    while IFS=\$'\\t' read -r col1 rest;do
        awk '{print \$1}' >> "${prefix}_viral_contig_list.txt"
    done < "${tsv}"

    sort -u "${prefix}_viral_contig_list.txt" -o "${prefix}_viral_contig_list.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        contig_sorter: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch viral_contig_list.txt
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        contig_sorter: "1.0.0"
    END_VERSIONS

    """
}