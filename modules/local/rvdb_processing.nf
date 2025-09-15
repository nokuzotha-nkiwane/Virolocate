process RVDB_PROCESSING{
    
    input:
    path rvdb_dir

    output:
    path "rvdb_final_accessions.tsv", emit: rvdb_fin_acc
    val "RVDB_PROCESSING v1.0.0" into version

    script:
    """
    rvdb_fin_acc="rvdb_final_accessions.tsv"
    #if working with RVDB, check if RVDB folder exists and isn't empty; if it doesnt only run ncbi part
    if [[ -d "${rvdb_dir}" ]] && [[ \$(find "${rvdb_dir}" -name "*.tsv" | wc -l) -gt 0 ]]; then
    echo "Using RVDB directory to make final file for all Diamond Blastx outputs"

        #check for empty files and skip them
        for matches in "${rvdb_dir}"/*.tsv;do
            if [[ -s "\${matches}" ]]; then
                echo -e "Processing \${matches}"

                #take nucleotide acc_id from diamond output file
                while IFS=\$'\\t' read -r col1 col2 col3 col4 rest; do
                    if [[ -n "\${col1}" ]] && [[ "\${col1}" != "#"* ]]; then
                        acc_id=\$(echo "\${col3}" | cut -d "|" -f3)
                        name=\$(echo "\${col4}" | cut -d "|" -f6)
                        echo -e "\${col1}\\t\${col2}\\t\${acc_id}\\t\${name}\\t\${rest}"
                    fi
                done < "\${matches}"
            else 
                echo "Skipping empty or non-existent files"
            fi
        done >> "\${rvdb_fin_acc}"

    #if directory or files empty
    else
        echo "RVDB directory does not exist or is empty. Searching for NCBI directory."
        echo "# No RVDB data processed" > "\${rvdb_fin_acc}"
    fi
    
    """
}