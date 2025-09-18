process RVDB_PROCESSING{
    
    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path('*.tsv'), emit: rvdb_final_acc
    val "RVDB_PROCESSING v1.0.0" into version

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def diamond_tsv = task.ext.${prefix}_diamond_tsv ?: ""
    def rvdb_final_acc = task.ext.rvdb_final_acc ?: ""
    """
    rvdb_fin_acc="rvdb_final_accessions.tsv"
    #if working with RVDB, check if RVDB folder exists and isn't empty; if it doesnt only run ncbi part
    if [[ -d "${rvdb_dir}" ]] && [[ \$(find "${rvdb_dir}" -name "*.tsv" | wc -l) -gt 0 ]]; then
    echo "Using RVDB directory to make final file for all Diamond Blastx outputs"

        #check for empty files and skip them
        for matches in "${rvdb_dir}"/*.tsv;do
            if [[ -s "${diamond_tsv}" ]]; then
                echo -e "Processing ${diamond_tsv}"

                #take nucleotide acc_id from diamond output file
                while IFS=\$'\\t' read -r col1 col2 col3 col4 rest; doyh
                    if [[ -n "\${col1}" ]] && [[ "\${col1}" != "#"* ]]; then
                        acc_id=\$(echo "\${col3}" | cut -d "|" -f3)
                        name=\$(echo "\${col4}" | cut -d "|" -f6)
                        echo -e "\${col1}\\t\${col2}\\t\${acc_id}\\t\${name}\\t\${rest}"
                    fi
                done < "${diamond_tsv}"
            else 
                echo "Skipping empty or non-existent files"
            fi
        done >> "${rvdb_final_acc}"

    #if directory or files empty
    else
        echo "RVDB directory does not exist or is empty. Searching for NCBI directory."
        echo "# No RVDB data processed" > "${rvdb_final_acc}"
    fi
    
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def rvdb_final_acc = task.ext.rvdb_final_acc ?: ""
    """ 
    touch ${rvdb_final_acc}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rvdb_processing: \$(echo \$(rvdb_processing -v 2>&1) | sed 's/RVDB_PROCESSING v//')
    END_VERSIONS

    """
}