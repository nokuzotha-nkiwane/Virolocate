process CONTIG_FILTER {

    input:
    tuple val(meta), path("*.tsv")
    //path "acc_tax_id.tsv"

    output:
    tuple val(meta), path("*.tsv"), emit: viral_contigs_tsv
    
    script:
    """
    viral_contigs_tsv = "viral_contigs.tsv"
    #contig filtering according to kingdom viruses
    #extract contig matches that are part of viruses
    while IFS=$'\\t' read -r col1 col2 col3 col4 rest; do
        if [[ \${col4} == *Virus* ]]; then
            echo -e "\${col1}\\t${col2}\\t${col4}\\t${rest}" >> "\${viral_contigs_tsv}"
        fi
    done < ${path("*.tsv")}
    """

    stub:
    """

    """
}