process NCBI_PROCESSING{

    input:
    path ncbi_dir
    path "../output", emit: in_dir 
    path "\${out_dir}/acc_tax_id.tsv", emit: in_tsv

    output:
    path "../output", emit: out_dir

    

    script:
    //to change into nextflow logic
    """
    #set file variables
    fin_acc=\${out_dir}/accessions.tsv
    

    if [[ -d "${ncbi_dir}" ]] && [[ \$(find "${ncbi_dir}" -name "*.tsv" | wc -l) -gt 0 ]]; then
        echo "Using NCBI folder for metadata file preparation"
        for matches in "${ncbi_dir}"/*.tsv; do
            cat "\${matches}" >> "\${fin_acc}"
        done

    else
        echo "Files in NCBI directory empty or do not exist."
    fi

    """
}