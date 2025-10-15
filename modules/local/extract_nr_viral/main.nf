process EXTRACT_NR_VIRAL {
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/4e50bd9df908/wave/build:extract_nr_viral--fea8de4b0b5f4627"

    input:
    path viral_csv
    tuple val(meta), path(nr_db)

    output:
    path('nr_viral_seqs.txt'), emit: nr_viral_seqs
    path('viral_ncbi.fasta'), emit: nr_db_fasta
    path "versions.yml"         , emit: versions

    script:

    """
    #filter csv for viral sequences
    awk -F',' '{print \$3}' "${viral_csv}" > nr_viral_seqs.txt

    #filter nr database for viral sequences 
    while read -r virus; do
        awk -v name="\${virus}" '
            BEGIN {IGNORECASE=1}
            /^>/ {ON = index(\$0, name) > 0}
            ON {print}
        ' "${nr_db}" >> viral_ncbi.fasta
    done < nr_viral_seqs.txt
    """

    stub: 

    """
    touch viral_ncbi.fasta
    touch nr_viral_seqs.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        extract_nr_viral: "1.0.0"
    END_VERSIONS

    """
}