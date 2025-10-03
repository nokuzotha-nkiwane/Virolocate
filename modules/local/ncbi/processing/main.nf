process NCBI_PROCESSING {
    tag "${meta.id}"
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/15d0d9436d7f/wave/build:ncbi_processing--b61e3e84fb1e5c3f"

    input:
    tuple val(meta), path('*.tsv')

    output:
    tuple val(meta), path('*.tsv')  , emit: tsv
    path "versions.yml"             , emit: versions


    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def diamond_tsv = task.ext.diamond_tsv ?: ""
    def ncbi_final_acc = task.ext.ncbi_final_acc ?: ""
    """
    if [[ -d "${ncbi_dir}" ]] && [[ \$(find "${ncbi_dir}" -name "*.tsv" | wc -l) -gt 0 ]]; then
        echo "Using NCBI folder for metadata file preparation"

       cat "${diamond_tsv}" >> "${ncbi_final_acc}"

    else
        echo "Files in NCBI directory empty or do not exist."
        exit 1
    fi

    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def diamond_tsv = task.ext.diamond_tsv ?: ""
    def ncbi_final_acc = task.ext.ncbi_final_acc ?: ""
    """
    touch ${prefix}.ncbi.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncbi_processing: "1.0.0"
    END_VERSIONS

    """
}
