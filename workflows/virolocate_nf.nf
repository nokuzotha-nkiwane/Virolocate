/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Check input path parameters to see if they exist
def checkPathParamList = [
    params.input,
    params.multiqc_config,
    params.rvdb_fasta,
    params.ncbi_nr_fasta,
    params.taxdb,
    params.ncbi_nt_db,
    params.trimmomatic_adapters
]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.samplesheet) { ch_samplesheet = file(params.samplesheet) } else { exit 1, 'Input samplesheet not specified!' }

/*

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl=2


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
include { DIAMOND_MAKEDB as DIAMOND_MAKE_NR_DB} from '../modules/nf-core/diamond/makedb/main'
include { DIAMOND_BLASTX as DIAMOND_BLASTX_PRE_RVDB} from '../modules/nf-core/diamond/blastx/main.nf'
include { DIAMOND_BLASTX as DIAMOND_BLASTX_PRE_NCBI} from '../modules/nf-core/diamond/blastx/main.nf'
include { DIAMOND_BLASTX as DIAMOND_BLASTX_FINAL } from '../modules/nf-core/diamond/blastx/main.nf'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_virolocate_nf_pipeline'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'

// import local modules
include { EXTRACT_NR_VIRAL } from '../modules/local/extract_nr_viral/main.nf'
include { FASTA_PROCESSING } from '../modules/local/fasta_processing/main.nf'
include { RVDB_PROCESSING } from '../modules/local/rvdb/processing/main.nf'
include { TAXONOMY_ID    } from '../modules/local/taxonomy_id/main.nf'
include { CONTIG_FILTER } from '../modules/local/contig_filter/main.nf'
include { MEGAHIT_RENAME } from '../modules/local/megahit_rename/main.nf'
include { CONTIG_UNIQUE_SORTER } from '../modules/local/contig_sorting/main.nf'
include { MAKE_BLAST_FASTA } from '../modules/local/make_blast_fasta/main.nf'
include { FETCH_METADATA as FETCH_METADATA_BLASTN} from '../modules/local/fetch_metadata/main.nf'
include { FETCH_METADATA as FETCH_METADATA_BLASTX} from '../modules/local/fetch_metadata/main.nf'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
ch_samplesheet= Channel.fromPath(params.samplesheet)

workflow VIROLOCATE_NF {
//    take:
//    ch_samplesheet

    //main starts main workflow logic
    //ch_versions will collect software version info form each tool
    //ch_multiqc_files will collect quality control reports for final aggregation
    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //Parse samplesheet to get reads
    //assumes paired end readsa as default
    ch_reads = ch_samplesheet
    .splitCsv(header:true)
    .map { row ->
        def meta = [ id: row.sample, single_end: row.fastq_2 ? false : true ]
        def reads = [ file(row.fastq_1), file(row.fastq_2) ]
        tuple(meta, reads)
    }

    // MODULE: Run FastQC

    FASTQC_PRE (ch_reads)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_PRE.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC_PRE.out.versions.first())


    //---------------------------------------

    //Trimmomatic run to trim reads
    //TODO: @nox Add a parameter to allow users to pass the folder location
    // Assuming fastq is a list of files [R1, R2] for paired-end
    ch_adapters = Channel.fromPath(params.trimmomatic_adapters)

    TRIMMOMATIC(ch_reads)
    // // NOTE: I'm not quite sure what's wrong with this line, the formatting
    // // seems to be fine. Therefore for the meantime, we can simply comment out
    // // this one.
    // // ch_versions = ch_versions.mix(TRIMMOMATIC.out.versions.first())

    //FastQC to check quality of trimmed reads
    FASTQC_POST(TRIMMOMATIC.out.trimmed_reads)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_POST.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC_POST.out.versions.first())

    //Megahit to assemble reads into contigs
    ch_trimmed_for_megahit = TRIMMOMATIC.out.trimmed_reads.map { meta, reads -> tuple(meta, reads[0], reads[1]) }

    MEGAHIT(ch_trimmed_for_megahit)
    // NOTE: I'm not quite sure what's wrong with this line, the formatting
    // seems to be fine. Therefore for the meantime, we can simply comment out
    // this one.
    // ch_versions = ch_versions.mix(MEGAHIT.out.versions.first())

    MEGAHIT_RENAME(MEGAHIT.out.contigs)

    //Diamond make_db to create diamond formatted rvdb and ncbi databases
    ch_rvdb_fasta = Channel.fromPath(params.rvdb_fasta).map { fasta -> [[id: 'rvdb'], fasta] }
    DIAMOND_MAKE_RVDB(ch_rvdb_fasta)

    // // NOTE: I'm not quite sure what's wrong with this line, the formatting
    // // seems to be fine. Therefore for the meantime, we can simply comment out
    // // this one.
    // // ch_versions = ch_versions.mix(DIAMOND_MAKE_RVDB.out.versions.first())

    // // ch_ncbi_nr_fasta = Channel.fromPath(params.ncbi_nr_fasta, checkIfExists: true).map { fasta -> [[id: 'ncbi_viral'], fasta] }.view()
    // // EXTRACT_NR_VIRAL(params.viral_csv, ch_ncbi_nr_fasta)

    // // ch_ncbi_viral = (EXTRACT_NR_VIRAL.out.fasta).map { fasta -> [[id: 'ncbi_viral'], fasta] }
    // // DIAMOND_MAKE_NCBI_DB(ch_ncbi_viral)
    // // // //ch_versions = ch_versions.mix(DIAMOND_MAKE_NCBI_DB.out.versions.first())


    // // //Diamond to compare read proteins against known proteins in databases
    // // // NOTE: In the bash script, we have the output extension as `m8` which is
    // // // just a TSV, therefore we shall use TSV directly to call the nf-core module.
    // // //TODO: @nox we need to add more parameters to this process-call

    ch_rvdb_dmnd_db = (DIAMOND_MAKE_RVDB.out.db).toList().map { it[0] }
    DIAMOND_BLASTX_PRE_RVDB(
        MEGAHIT_RENAME.out.contigs,
        ch_rvdb_dmnd_db,
        params.diamond_output_format,
        ''
    )
    // // // ch_versions = ch_versions.mix(DIAMOND_BLASTX_PRE_RVDB.out.versions.first())

    // // ch_ncbi_dmnd_db = (DIAMOND_MAKE_NCBI_DB.out.db).toList().map { it[0] }
    // //  DIAMOND_BLASTX_PRE_NCBI(
    // //     MEGAHIT_RENAME.out.contigs,
    // //     ch_ncbi_dmnd_db,
    // //     params.diamond_output_format,
    // //     ''
    // // )
    // // // NOTE: I'm not quite sure what's wrong with this line, the formatting
    // // // seems to be fine. Therefore for the meantime, we can simply comment out
    // // // this one.
    // // // ch_versions = ch_versions.mix(DIAMOND_BLASTX_PRE_NCBI.out.versions.first())

    RVDB_PROCESSING(DIAMOND_BLASTX_PRE_RVDB.out.tsv)
    ch_versions = ch_versions.mix(RVDB_PROCESSING.out.versions.first())

    // // RENAME THE FILES IN THE CHANNELS SO THE SAME SAMPLE NAMES CAN BE PROCESSED SEPARATELY ADN NOT OVERWRITE EACH OTHER
    // //get accession ids and taxonomy ids for taxonkit to use
    // // ch_rvdb = (RVDB_PROCESSING.out.tsv) ?: Channel.empty()
    // // ch_ncbi = (DIAMOND_BLASTX_NCBI.out.tsv) ?: Channel.empty()
    // // ch_combined_diamond_output = (ch_rvdb).mix(ch_ncbi).map {it[1]}
    TAXONOMY_ID(RVDB_PROCESSING.out.tsv)
    ch_versions = ch_versions.mix(TAXONOMY_ID.out.versions.first())

    //Taxonkit for lineage filtering and getting taxonomy ids
    ch_taxonkit_db = Channel.fromPath(params.taxdb, checkIfExists: true)
    ch_db_mapped = ch_taxonkit_db.toList().map { it[0] }
    ch_taxonkit_input = TAXONOMY_ID.out.tsv.map {meta, taxidfile -> [meta, null, taxidfile]}

    TAXONKIT_LINEAGE(ch_taxonkit_input, ch_db_mapped)
    ch_versions = ch_versions.mix(TAXONKIT_LINEAGE.out.versions.first())

    //Contig_filter to extract sequences marked as viral only
    CONTIG_FILTER(TAXONKIT_LINEAGE.out.tsv)
    ch_versions = ch_versions.mix(CONTIG_FILTER.out.versions.first())

    // //sort the filtered list to remove duplicates
    CONTIG_UNIQUE_SORTER(CONTIG_FILTER.out.tsv)
    ch_versions = ch_versions.mix(CONTIG_UNIQUE_SORTER.out.versions.first())

    //make fasta file to blastn against NT
    ch_joined = (CONTIG_UNIQUE_SORTER.out.txt).join(MEGAHIT_RENAME.out.contigs)
    MAKE_BLAST_FASTA(ch_joined)
    ch_versions = ch_versions.mix(MAKE_BLAST_FASTA.out.versions.first())

    ch_all = MAKE_BLAST_FASTA.out.fasta.map {meta, fasta-> [fasta]}.collect({it})
    FASTA_PROCESSING(ch_all)
    ch_blast_fasta = (FASTA_PROCESSING.out.fasta).map { fasta -> tuple([id:'final'], fasta) }.view()
    // Blastn for comparing contig sequences to known nucleotide sequences
    ch_ncbi_nt_db = Channel.fromPath(params.ncbi_nt_db, checkIfExists: true).map {db -> [[id:"ncbi_nt"], db]}.view()
    ch_taxids = Channel.value(false).view()
    ch_taxidlist = Channel.fromPath(params.taxidlist).view()

    ch_negative_tax = Channel.value(false).view()

    BLAST_BLASTN(ch_blast_fasta, ch_ncbi_nt_db, ch_taxidlist, ch_taxids, ch_negative_tax)
    ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions.first())

    // // //get metadata of the blastn hits
    // // FETCH_METADATA_BLASTN(BLAST_BLASTN.out.txt)
    // // ch_versions = ch_versions.mix(FETCH_METADATA_BLASTN.out.versions.first())

    // // //Make nr database using nr fasta
    ch_nr_fasta = Channel.fromPath(params.ncbi_nr_fasta, checkIfExists: true)
                .map { fasta -> [[id: 'nr'], fasta] }
    DIAMOND_MAKE_NR_DB(ch_nr_fasta)
    // // ch_versions = ch_versions.mix(DIAMOND_MAKE_NR_DB.out.versions.first())

    // //Blastx to compare proteins to check for distant orthologs
    ch_diamond_blastx_final_in = Channel.fromPath(params.diamond_blastx_final) ?: DIAMOND_MAKE_NR_DB.out.db

    DIAMOND_BLASTX_FINAL(
        ch_blast_fasta,
        ch_diamond_blastx_final_in,
        params.diamond_output_format,
        ''
    )
    // ch_versions = ch_versions.mix(DIAMOND_BLASTX_FINAL.out.versions.first())

    // //get metadata of the blastx hits
    // FETCH_METADATA_BLASTX(DIAMOND_BLASTX_FINAL.out.tsv)
    // ch_versions = ch_versions.mix(FETCH_METADATA_BLASTX.out.versions.first())


    //---------------------------------------
    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'virolocate_nf_software_'  + 'mqc_'  + 'versions.yml',
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
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// workflow.onComplete {
//     if (params.email || params.email_on_fail) {
//         NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
//     }
//     NfcoreTemplate.summary(workflow, params, log)
//     if (params.hook_url) {
//         NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
//     }
// }


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
