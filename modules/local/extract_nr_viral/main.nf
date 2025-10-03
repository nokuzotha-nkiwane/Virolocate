process EXTRACT_NR_VIRAL {
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/4e50bd9df908/wave/build:extract_nr_viral--fea8de4b0b5f4627"

    input:
    val viruses_csv
    tuple val(meta), path(nr_db)

    output:
    tuple val(meta), path('*.txt'), emit: nr_viral_seqs
    tuple val(meta), path('*.fasta'), emit: nr_db_fasta
    path "versions.yml"         , emit: versions

    script:
    def viruses_csv = task.ext.viruses_csv
    def nr_viral_seqs = task.ext.nr_viral_seqs 
    def nr_db_fasta = task.ext.nr_db_fasta 

    """
    #filter csv for viral sequences
    awk -F',' '{print \$3}' "${viruses_csv}" >> "${nr_viral_seqs}"

    #filter nr database for viral sequences 
    while read -r virus; do
        awk -v name="\${virus}" '
            BEGIN {IGNORECASE=1}
            /^>/ {ON = index(\$0, name) > 0}
            ON {print}
        ' "${params.blastx_nr_fasta}" >> "${nr_db_fasta}"
    done < ${nr_viral_seqs}
    """

    stub:
    def nr_viral_seqs = task.ext.nr_viral_seqs 
    def nr_db_fasta = task.ext.nr_db_fasta 

    """
    touch nr_db.fasta
    touch nr_viral_seqs.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        extract_nr_viral: "1.0.0"
    END_VERSIONS

    """
}