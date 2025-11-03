process PROTEIN_MERGER {
    tag "${meta.id}"
    label 'process_high'
    label 'process_long'

    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/cf2847dec15c/wave/build:taxonomy_id--5d733d140ee5728f"

    input:
    tuple val(meta), path(tsv), path(tsvs) 


    output:
    tuple val(meta), path('*.tsv')  , emit: tsv
    path "versions.yml"             , emit: versions

    script:
    """
    cat ${tsvs.join(' ')} | tr -d '\r' > metadata.txt 
    #grep -F -w -f accessions.txt ${tsv} > ${meta.id}_matches.txt
    sort -k1,1 metadata.txt  -o metadata2.txt
    sort -k2,2 ${meta.id}_matches.txt -o ${meta.id}_matches2.txt
    join -t \$'\\t' -1 2 -2 1 ${meta.id}_matches2.txt metadata2.txt > ${meta.id}.tsv
            
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        protein_merger: "1.0.0"
    END_VERSIONS
    """

    stub:

    """
    touch _check.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        protein_merger: "1.0.0"
    END_VERSIONS

    """
}
