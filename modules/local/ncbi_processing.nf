process NCBI_PROCESSING{

    input:
    path ncbi_dir

    output:
    path "ncbi_final_accessions.tsv", emit: ncbi_fin_acc
    val "NCBI_PROCESSING v1.0.0" into version
    

    script:
    """
    ncbi_acc="ncbi_final_accessions.tsv"
    if [[ -d "${ncbi_dir}" ]] && [[ \$(find "${ncbi_dir}" -name "*.tsv" | wc -l) -gt 0 ]]; then
        echo "Using NCBI folder for metadata file preparation"

        #create empty file 
        > "\${ncbi_acc}"
        for matches in "${ncbi_dir}"/*.tsv; do
            cat "\${matches}" >> "\${ncbi_acc}"
        done
    else
        echo "Files in NCBI directory empty or do not exist."
        exit 1
    fi

    """
    stub:
    """

    """
}