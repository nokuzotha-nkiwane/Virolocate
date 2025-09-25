process NCBI_PROCESSING{
    tag "$meta.id"
    conda "${moduleDir}/environment.yml"
    container "${wave.seqera.io/wt/15d0d9436d7f/wave/build:ncbi_processing--b61e3e84fb1e5c3f}"

    input:
    tuple val(meta), path('*.tsv')

    output:
    tuple val(meta), path('*.tsv')  , emit: ncbi_final_acc
    path "versions.yml"             , emit: versions
    

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def diamond_tsv = task.ext.diamond_tsv ?: ""
    def ncbi_final_acc = task.ext.ncbi_final_acc ?: ""
    """
    ncbi_acc="ncbi_final_accessions.tsv"
    if [[ -d "${ncbi_dir}" ]] && [[ \$(find "${ncbi_dir}" -name "*.tsv" | wc -l) -gt 0 ]]; then
        echo "Using NCBI folder for metadata file preparation"

        for "${diamond_tsv}; do
            cat "${diamond_tsv}" >> "${ncbi_final_acc}"
        done
    else
        echo "Files in NCBI directory empty or do not exist."
        exit 1
    fi

    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def ncbi_final_acc = task.ext.ncbi_final_acc ?: ""
    """ 
    touch ${ncbi_final_acc}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rvdb_processing: \$(echo \$(rvdb_processing -v 2>&1) | sed 's/RVDB_PROCESSING v//')
    END_VERSIONS

    """
}

