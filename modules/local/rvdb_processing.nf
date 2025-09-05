process RVDB_PROCESSING{
    
    input:
    path rvdb_dir

    output:
    path "../output", emit: out_dir
    

    script:
    //to change into nextflow logic
    """
    #set file variables
    rv_acc=\${rvdb_dir}/rvdb_acc_ids.tsv
    fin_acc=\${out_dir}/accessions.tsv

    #clear existing files
    > \${rv_acc}
    > \${fin_acc}

    #if working with RVDB, check if RVDB folder exists and isn't empty; if it doesnt only run ncbi part
    if [[ -d "${rvdb_dir}" ]] && [[ \$(find "${rvdb_dir}" -name "*.tsv" | wc -l) -gt 0 ]]; then

        #check for empty files and skip them
        for matches in "${rvdb_dir}"/*.tsv;do
            if [[ -f "\${matches}" ]]; then

                #take nucleotide acc_id from diamond output file
                while read -r col1 col2 col3 col4 rest; do
                    acc_id=\$(echo "\${col3}" | cut -d "|" -f3)
                    name=\$(echo "\${col4}" | cut -d "|" -f6)
                    echo -e "\${col1}\\t\${col2}\\t\${acc_id}\\t\${name}\\t\${rest}"
                done < "\${matches}"
            fi
        done >> "\${rv_acc}"

    #if directory or files empty
    else
        echo "RVDB directory does not exist. Searching for NCBI directory."
    fi

    #if the rvdb file exists and has a non-empty acc-ids.txt file
    if [[ -s "\${rv_acc}" ]]; then
        cat "\${rv_acc}" >> "\${fin_acc}"
    fi
    
    """
}