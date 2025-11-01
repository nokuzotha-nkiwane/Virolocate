process FETCH_METADATA_BLASTN {
    maxForks 3
    label 'process_long'
    // conda "${moduleDir}/environment.yml"
    // container "wave.seqera.io/wt/9dc43bf827c0/wave/build:fetch_metadata--94bd174222c6a1e2"
    
    input:
    tuple val(meta), path(txt)

    output:
    tuple val(meta), path('*_final.gb')  , emit: gb
    path "versions.yml"             , emit: versions

    script:
    def name = txt.getBaseName()
    """
    accessions=\$(cat ${txt})
    url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=\${accessions}&rettype=gb&retmode=text" 
    curl -N -L --retry 5 --retry-delay 5 \${url1} -o ${name}_1.gb

    ON=0
    ACC=""

    while IFS= read -r line; do
        if [[ "\$line" =~ ^LOCUS ]]; then
            if [[ "\$ON" -eq 1 ]]; then
                echo "\$ACC" >> ${name}_missing.lst
            fi
            ON=1
            ACC=""
            continue
        fi

        if [[ "\$line" =~ ^ACCESSION ]]; then
            ACC=\$(echo "\$line" | awk '{print \$2}')
            continue
        fi

        if [[ "\$line" =~ ^// ]]; then
            ON=0
            ACC=""
            continue
        fi
    done < ${name}_1.gb

    if [[ "\$ON" -eq 1 && -n "\$ACC" ]]; then
        echo "\$ACC" >> ${name}_missing.lst
    fi

    if [[ -s ${name}_missing.lst && \$(grep -cv '^[[:space:]]*\$' ${name}_missing.lst) -eq 0 ]]; then
        awk 'NF' ${name}_missing.lst >> ${name}_missing_1.lst
        tr '\\n' ',' < ${name}_missing_1.lst | sed 's/,\$/\\n/' > ${name}_missing_final.lst
        accessions=\$(cat ${name}_missing_final.lst)
        url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=\${accessions}&rettype=gb&retmode=text" 
        curl -N -L --retry 5 --retry-delay 5 \${url1} -o ${name}_2.gb
    else
        touch ${name}_2.gb
    fi

    cat ${name}_1.gb > ${name}_final.gb
    awk 'NF' "${name}_2.gb" >> "${name}_final.gb"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fetch_metadata: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch _blastn_metadata.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fetch_metadata: "1.0.0"
    END_VERSIONS
    """
}