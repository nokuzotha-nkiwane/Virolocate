/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// import nf-core modules
include { BLAST_BLASTN } from '../modules/nf-core/blast/blastn/main.nf'
include { FASTQC as FASTQC_INIT  } from '../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_FINAL   } from '../modules/nf-core/fastqc/main'
include { MEGAHIT } from '../modules/nf-core/megahit/main.nf'
include { MULTIQC } from '../modules/nf-core/multiqc/main.nf'
include { TAXONKIT_LINEAGE } from '../modules/nf-core/taxonkit/lineage/main.nf'
include { TRIMMOMATIC } from '../modules/nf-core/trimmomatic/main.nf'
include { DIAMOND_BLASTX as DIAMOND_BLASTX_INIT } from '../modules/nf-core/diamond/blastx/main.nf'
include { DIAMOND_BLASTX as DIAMOND_BLASTX_FINAL } from '../modules/nf-core/diamond/blastx/main.nf'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_virolocate-nf_pipeline'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'

// import local modules
include { NCBI_PROCESSING } from '../modules/local/ncbi_processing.nf'
include { RVDB_PROCESSING } from '../modules/local/rvdb_processing.nf'
include { TAXONOMY_ID    } from '../modules/local/taxonomy_id.nf'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow VIROLOCATE_NF {

    //take input data
    take:
        ch_samplesheet
    
    //main starts main workflow logic
    //ch_versions will collect software version info form each tool
    //ch_multiqc_files will collect quality control reports for final aggregation
    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    //
    // MODULE: Run FastQC
    //
    FASTQC_INIT (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_INIT.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC_INIT.out.versions.first())

    //---------------------------------------

    //Trimmomatic run to trim reads
    //TODO: @nox Add a parameter to allow users to pass the folder location
    ch_reads = ch_samplesheet.map { meta, fastq ->
        // Assuming fastq is a list of files [R1, R2] for paired-end
        [meta, fastq]
    }
    
    TRIMMOMATIC(
        ch_reads,
        params.trimmomatic_adapters ?: []
    )
    ch_versions = ch_versions.mix(TRIMMOMATIC.out.versions.first())


    //FastQC to check quality of trimmed reads
    FASTQC_FINAL(
        TRIMMOMATIC.out.trimmed_reads
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_FINAL.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC_FINAL.out.versions.first())

    //Megahit to assemble reads into contigs
    //TODO: @nox we need to transform the shape of TRIMMOMATIC.out.trimmed_reads
    //such that it aligns with the expectation of MEGAHIT
    ch_megahit_input = TRIMMOMATIC.out.trimmed_reads.map { meta, reads ->
    [meta, reads, []]
    }

    MEGAHIT(
        ch_megahit_input
    )
    ch_versions = ch_versions.mix(MEGAHIT.out.versions.first())

    //Diamond to compare read proteins against known protiens in databases
    // NOTE: In the bash script, we have the output extension as `m8` which is
    // just a TSV, therefore we shall use TSV directly to call the nf-core module.
    //TODO: @nox we need to add more parameters to this process-call
    ch_diamond_db = params.diamond_db ? 
        Channel.fromPath(params.diamond_db, checkIfExists: true).map { db -> [[id: 'diamond_db'], db] } :
        Channel.empty()

    ch_diamond_input = MEGAHIT.out.contigs.combine(ch_diamond_db.map { meta, db -> db })


    DIAMOND_BLASTX_INIT(
        ch_diamond_input.map { meta, contigs, db -> [meta, contigs] },
        ch_diamond_db.map { meta, db -> db },
        params.diamond_output_format ?: 'tsv',
        []  
    )
    
    ch_versions = ch_versions.mix(DIAMOND_BLASTX_INIT.out.versions.first())


    //get accession ids and taxonomy ids for taxonkit to use
    NCBI_PROCESSING(
        DIAMOND_BLASTX_INIT.out.tsv
    )
    ch_versions = ch_versions.mix(NCBI_PROCESSING.out.versions.first())

    RVDB_PROCESSING(
        DIAMOND_BLASTX_INIT.out.tsv
    )
    ch_versions = ch_versions.mix(RVDB_PROCESSING.out.versions.first())


    //get accession ids and taxonomy ids for taxonkit to use
    TAXONOMY_ID(
    RVDB_PROCESSING.out.rvdb_fin_acc,
    NCBI_PROCESSING.out.ncbi_fin_acc
    )

    ch_versions = ch_versions.mix(TAXONOMY_ID.out.versions.first())

    //Taxonkit for lineage filtering and getting taxonomy ids
    ch_taxonkit_db = params.taxonkit_db ?
        Channel.fromPath(params.taxonkit_db, checkIfExists: true) :
        Channel.empty()

    TAXONKIT_LINEAGE(
        TAXONOMY_ID.out.tsv,
        ch_taxonkit_db.ifEmpty([])
    )
    ch_versions = ch_versions.mix(TAXONKIT_LINEAGE.out.versions.first())

    //Blastn for comparing contig sequences to knwon nucleotide sequences
    ch_blast_db = params.blast_db ?
        Channel.fromPath("${params.blast_db}*", checkIfExists: true).collect().map { files -> [[id: 'blast_db'], files] } :
        Channel.empty()

    BLAST_BLASTN(
        TAXONKIT_LINEAGE.out.tsv,
        ch_blast_db.map { meta, db -> db }
    )
    ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions.first())

    //Blastx to compare proteins to check for distant orthologs
    DIAMOND_BLASTX_FINAL(
        BLAST_BLASTN.out.txt,
        ch_diamond_db.map { meta, db -> db },
        params.diamond_output_format ?: 'tsv',
        []
    )
    ch_versions = ch_versions.mix(DIAMOND_BLASTX_FINAL.out.versions.first())


    //---------------------------------------
    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'virolocate-nf_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
