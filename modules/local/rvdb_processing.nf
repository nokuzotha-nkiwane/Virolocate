process RVDB_PROCESSING{
    
    input:
    tuple val(meta) , path(rvdb_dir), emit: rvdb_dir
    

    output:
    tuple val(meta) , path(final_accessions), emit: fin_acc
    

    script:
    """
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
        done >> "${fin_acc}"

    #if directory or files empty
    else
        echo "RVDB directory does not exist. Searching for NCBI directory."
    fi
    
    """
}