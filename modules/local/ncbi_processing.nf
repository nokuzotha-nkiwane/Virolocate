process NCBI_PROCESSING{

    input:
    tuple val(meta) , path(ncbi_dir), emit: ncbi_dir
    tuple val(meta) , path(final_accessions), emit: in_fin_acc

    output:
    tuple val(meta) , path(final_accessions), emit: fin_acc
    
    

    script:
    """
    if [[ -d "${ncbi_dir}" ]] && [[ \$(find "${ncbi_dir}" -name "*.tsv" | wc -l) -gt 0 ]]; then
        echo "Using NCBI folder for metadata file preparation"
        for matches in "${ncbi_dir}"/*.tsv; do
            cat "\${matches}" >> "${fin_acc}"
        done

    else
        echo "Files in NCBI directory empty or do not exist."
    fi

    """
}