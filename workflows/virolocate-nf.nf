/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// import nf-core modules
include { BLAST_BLASTN } from '../modules/nf-core/blast/blastn/main.nf'
include { FASTQC as FASTQC_PRE  } from '../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_POST   } from '../modules/nf-core/fastqc/main'
include { MEGAHIT } from '../modules/nf-core/megahit/main.nf'
include { MULTIQC } from '../modules/nf-core/multiqc/main.nf'
include { TAXONKIT_LINEAGE } from '../modules/nf-core/taxonkit/lineage/main.nf'
include { TRIMMOMATIC } from '../modules/nf-core/trimmomatic/main.nf'
include { DIAMOND_MAKEDB as DIAMOND_MAKE_RVDB } from '../modules/nf-core/diamond/makedb/main' 
include { DIAMOND_MAKEDB as DIAMOND_MAKE_NCBI_DB} from '../modules/nf-core/diamond/makedb/main' 
include { DIAMOND_BLASTX as DIAMOND_BLASTX_PRE_RVDB} from '../modules/nf-core/diamond/blastx/main.nf'
include { DIAMOND_BLASTX as DIAMOND_BLASTX_PRE_NCBI} from '../modules/nf-core/diamond/blastx/main.nf'
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
    FASTQC_PRE (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_PRE.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC_PRE.out.versions.first())

    //---------------------------------------

    //Trimmomatic run to trim reads
    //TODO: @nox Add a parameter to allow users to pass the folder location
    // Assuming fastq is a list of files [R1, R2] for paired-end
    ch_reads = ch_samplesheet.map { meta, fastq ->
        [meta, fastq]
    }
    
    TRIMMOMATIC(
        ch_reads, params.trimmomatic_adapters,
        []
    )
    ch_versions = ch_versions.mix(TRIMMOMATIC.out.versions.first())

    //FastQC to check quality of trimmed reads
    FASTQC_POST(
        TRIMMOMATIC.out.unpaired_reads ?: TRIMMOMATIC.out.trimmed_reads
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_POST.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC_POST.out.versions.first())

    //Megahit to assemble reads into contigs
    //TODO: @nox we need to transform the shape of TRIMMOMATIC.out.trimmed_reads
    //such that it aligns with the expectation of MEGAHIT
    ch_megahit_paired_input = TRIMMOMATIC.out.trimmed_reads.map { meta, reads ->
    [meta, reads]
    }

    MEGAHIT(
        ch_megahit_paired_input,
        []
    )
    ch_versions = ch_versions.mix(MEGAHIT.out.versions.first())

    //Diamond make_db to create a diamond formatted rvdb and ncbi databases
    DIAMOND_MAKE_RVDB(
        params.rvdb_fasta,
        [] 
    )
    //ch_rvdb_dmnd=DIAMOND_MAKE_RVDB_DB(params.rvdb_fasta)
    ch_versions = ch_versions.mix(DIAMOND_MAKE_RVDB.out.versions.first())

    DIAMOND_MAKE_NCBI_DB(
        params.ncbi_fasta,
        [] 
    )
    //ch_ncbi_dmnd=DIAMOND_MAKE_NCBI_DB(params.ncbi_fasta)
    ch_versions = ch_versions.mix(DIAMOND_MAKE_NCBI_DB.out.versions.first())


    //Diamond to compare read proteins against known protiens in databases
    // NOTE: In the bash script, we have the output extension as `m8` which is
    // just a TSV, therefore we shall use TSV directly to call the nf-core module.
    //TODO: @nox we need to add more parameters to this process-call
    
    //are these channels structured correctly to catch dmnd dbs made by diamond make_db
    ch_diamond_rvdb_db = (DIAMOND_MAKE_RVDB.out.db).map { meta, db -> db }
    ch_diamond_ncbi_db = (DIAMOND_MAKE_NCBI_DB.out.db).map { meta, db -> db }
    ch_diamond_input = (MEGAHIT.out.contigs).map { meta, contigs, db -> [meta, contigs] }

    DIAMOND_BLASTX_PRE_RVDB(
        ch_diamond_input,
        ch_diamond_rvdb_db,
        params.diamond_output_format ?: 'tsv',
        []
    )
    
    ch_versions = ch_versions.mix(DIAMOND_BLASTX_PRE_RVDB.out.versions.first())

     DIAMOND_BLASTX_PRE_NCBI(
        ch_diamond_input,
        ch_diamond_ncbi_db,
        params.diamond_output_format ?: 'tsv',
        []  
    )
    
    ch_versions = ch_versions.mix(DIAMOND_BLASTX_PRE_NCBI.out.versions.first())

    //get accession ids and taxonomy ids for taxonkit to use
    NCBI_PROCESSING(
        DIAMOND_BLASTX_PRE_RVDB.out.tsv
    )
    ch_versions = ch_versions.mix(NCBI_PROCESSING.out.versions.first())

    RVDB_PROCESSING(
        DIAMOND_BLASTX_PRE_NCBI.out.tsv
    )
    ch_versions = ch_versions.mix(RVDB_PROCESSING.out.versions.first())


    //get accession ids and taxonomy ids for taxonkit to use
    TAXONOMY_ID(
    RVDB_PROCESSING.out.rvdb_fin_acc,
    NCBI_PROCESSING.out.ncbi_fin_acc
    )

    ch_versions = ch_versions.mix(TAXONOMY_ID.out.versions.first())

    //Taxonkit for lineage filtering and getting taxonomy ids
    ch_taxonkit_db = (params.taxonkit_db).ifEmpty([])
        Channel.fromPath(params.taxonkit_db, checkIfExists: true) :
        Channel.empty()

    TAXONKIT_LINEAGE(
        TAXONOMY_ID.out.tsv,
        ch_taxonkit_db,
        []
    )
    ch_versions = ch_versions.mix(TAXONKIT_LINEAGE.out.versions.first())

    //Blastn for comparing contig sequences to knwon nucleotide sequences
    ch_blastn_db = (params.blastn_db).map { meta, db -> db }
        Channel.fromPath("${params.blastn_db}*", checkIfExists: true).collect().map { files -> [[id: 'blastn_db'], files] } :
        Channel.empty()

    BLAST_BLASTN(
        TAXONKIT_LINEAGE.out.tsv,
        ch_blastn_db,
        []
    )
    ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions.first())

    

    //Blastx to compare proteins to check for distant orthologs
    ch_final_diamond_db = (params.final_blastx_db).map { meta, db -> db }

    DIAMOND_BLASTX_FINAL(
        BLAST_BLASTN.out.txt,
        ch_final_diamond_db.map,
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
