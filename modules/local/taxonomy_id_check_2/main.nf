process TAXONOMY_ID_CHECK {
    tag "${meta.id}"
    maxForks 3
    label 'process_long'

    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/cf2847dec15c/wave/build:taxonomy_id--5d733d140ee5728f"

    input:
    tuple val(meta), path(tsv) 


    output:
    tuple val(meta), path('*_check.txt')  , emit: txt
    path "versions.yml"             , emit: versions

    script:
    def name = tsv.getBaseName()
    """
    while IFS=\$'\\t' read -r -a fields; do
        if [[ "\${fields[10]}" == "NA" ]]; then
            printf "%s\\t" "\${fields[@]}" >> "${name}_check.txt"
            echo >> "${name}_check.txt"
        fi
    done < "${tsv}"

    if [[ ! -s "${name}_check.txt" ]]; then
        echo > "${name}_check.txt"
    fi
            
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id_check: "1.0.0"
    END_VERSIONS
    """

    stub:

    """
    touch _check.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id_check: "1.0.0"
    END_VERSIONS

    """
}
