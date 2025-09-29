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
    params.taxonkit_db,
    params.ncbi_nt_fasta,
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
include { EXTRACT_NR_VIRAL } from '../modules/local/extract_nr_viral/extract_nr_viral.nf'
include { NCBI_PROCESSING } from '../modules/local/ncbi/processing/main.nf'
include { RVDB_PROCESSING } from '../modules/local/rvdb/processing/main.nf'
include { TAXONOMY_ID    } from '../modules/local/taxonomy_id/taxonomy_id.nf'
include { CONTIG_FILTER } from '../modules/local/contig_filter/contig_filter.nf'
include { CONTIG_UNIQUE_SORTER } from '../modules/local/contig_sorting/sorter.nf'
include { MAKE_BLAST_FASTA } from '../modules/local/make_blast_fasta/make_blast_fasta.nf'
include { FETCH_METADATA as FETCH_METADATA_BLASTN} from '../modules/local/fetch_metadata/metadata.nf'
include { FETCH_METADATA as FETCH_METADATA_BLASTX} from '../modules/local/fetch_metadata/metadata.nf'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
ch_samplesheet = Channel.fromPath(params.samplesheet)

workflow VIROLOCATE_NF {

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
        def reads = row.fastq_2 ? [ file(row.fastq_1), file(row.fastq_2) ]
                                : [ file(row.fastq_1) ]
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


    TRIMMOMATIC(ch_reads)
    // NOTE: I'm not quite sure what's wrong with this line, the formatting
    // seems to be fine. Therefore for the meantime, we can simply comment out
    // this one.
    // ch_versions = ch_versions.mix(TRIMMOMATIC.out.versions.first())

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

    //Diamond make_db to create diamond formatted rvdb and ncbi databases
    ch_rvdb_fasta = Channel.fromPath(params.rvdb_fasta).map { fasta -> [[id: 'rvdb'], fasta] }

    //channels for stub test should i keep them??
    ch_taxonmap = Channel.fromPath(params.taxonmap)
    ch_taxonnodes = Channel.fromPath(params.taxonnodes)
    ch_taxonnames = Channel.fromPath(params.taxonnames)

    DIAMOND_MAKE_RVDB(ch_rvdb_fasta, ch_taxonmap, ch_taxonnodes, ch_taxonnames)
    // NOTE: I'm not quite sure what's wrong with this line, the formatting
    // seems to be fine. Therefore for the meantime, we can simply comment out
    // this one.
    // ch_versions = ch_versions.mix(DIAMOND_MAKE_RVDB.out.versions.first())

    ch_ncbi_nr_fasta = Channel.fromPath(params.ncbi_nr_fasta, checkIfExists: true).map { fasta -> [[id: 'ncbi'], fasta] }

    ch_extraction_input = Channel.fromPath(params.viral_csv)
    EXTRACT_NR_VIRAL(ch_extraction_input, ch_ncbi_nr_fasta)
    DIAMOND_MAKE_NCBI_DB(EXTRACT_NR_VIRAL.out.nr_db_fasta, ch_taxonmap, ch_taxonnodes, ch_taxonnames)
    //ch_versions = ch_versions.mix(DIAMOND_MAKE_NCBI_DB.out.versions.first())


    //Diamond to compare read proteins against known proteins in databases
    // NOTE: In the bash script, we have the output extension as `m8` which is
    // just a TSV, therefore we shall use TSV directly to call the nf-core module.
    //TODO: @nox we need to add more parameters to this process-call

    // //are these channels structured correctly to catch dmnd dbs made by diamond make_db

    DIAMOND_BLASTX_PRE_RVDB(
        MEGAHIT.out.contigs,
        DIAMOND_MAKE_RVDB.out.db,
        params.diamond_output_format,
        ''
    )

    // ch_versions = ch_versions.mix(DIAMOND_BLASTX_PRE_RVDB.out.versions.first())


     DIAMOND_BLASTX_PRE_NCBI(
        MEGAHIT.out.contigs,
        DIAMOND_MAKE_NCBI_DB.out.db,
        params.diamond_output_format,
        ''
    )

    // NOTE: I'm not quite sure what's wrong with this line, the formatting
    // seems to be fine. Therefore for the meantime, we can simply comment out
    // this one.
    // ch_versions = ch_versions.mix(DIAMOND_BLASTX_PRE_NCBI.out.versions.first())

    // //get accession ids and taxonomy ids for taxonkit to use
    RVDB_PROCESSING(DIAMOND_BLASTX_PRE_NCBI.out.tsv)
    ch_versions = ch_versions.mix(RVDB_PROCESSING.out.versions.first())

    NCBI_PROCESSING(DIAMOND_BLASTX_PRE_RVDB.out.tsv)
    ch_versions = ch_versions.mix(NCBI_PROCESSING.out.versions.first())

    //get accession ids and taxonomy ids for taxonkit to use
    TAXONOMY_ID(RVDB_PROCESSING.out.tsv, NCBI_PROCESSING.out.tsv)
    ch_versions = ch_versions.mix(TAXONOMY_ID.out.versions.first())

    //Taxonkit for lineage filtering and getting taxonomy ids
    ch_taxonkit_db = Channel.fromPath(params.taxdb, checkIfExists: true)
    ch_taxonkit_input = TAXONOMY_ID.out.acc_tax_id_tsv.map { meta, taxidfile ->
    tuple(meta, "ALL", taxidfile)
    }


    TAXONKIT_LINEAGE(ch_taxonkit_input, ch_taxonkit_db)

    ch_versions = ch_versions.mix(TAXONKIT_LINEAGE.out.versions.first())

    //Contig_filter to extract sequences marked as viral only
    CONTIG_FILTER(TAXONKIT_LINEAGE.out.tsv)
    ch_versions = ch_versions.mix(CONTIG_FILTER.out.versions.first())

    //sort the filtered list to remove duplicates
    CONTIG_UNIQUE_SORTER(CONTIG_FILTER.out.viral_contigs_metadata)
    ch_versions = ch_versions.mix(CONTIG_UNIQUE_SORTER.out.versions.first())

    //make fasta file to blastn against NT
    MAKE_BLAST_FASTA(CONTIG_UNIQUE_SORTER.out.viral_contig_list)
    ch_versions = ch_versions.mix(MAKE_BLAST_FASTA.out.versions.first())

    //Blastn for comparing contig sequences to known nucleotide sequences
    ch_ncbi_nt_db = Channel.fromPath("${params.ncbi_nt_db}/*", checkIfExists: true).collect()
    BLAST_BLASTN(MAKE_BLAST_FASTA.out.blast_contigs_fasta, ch_ncbi_nt_db)
    // ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions.first())

    // //get metadata of the blastn hits
    // FETCH_METADATA_BLASTN(BLAST_BLASTN.out.tsv)
    // ch_versions = ch_versions.mix(FETCH_METADATA_BLASTN.out.versions.first())

    // //Make nr database using nr fasta
    // ch_nr_fasta = Channel.fromPath(params.ncbi_nr_fasta, checkIfExists: true).map { fasta -> [[id: 'nr'], fasta] }
    // DIAMOND_MAKE_NR_DB(ch_nr_fasta, ch_taxonmap, ch_taxonnodes, ch_taxonnames)
    // ch_versions = ch_versions.mix(DIAMOND_MAKE_NR_DB.out.versions.first())

    // //Blastx to compare proteins to check for distant orthologs
    // ch_diamond_nr_db = DIAMOND_MAKE_NR_DB.out.db.map { meta, db -> db }
    // DIAMOND_BLASTX_FINAL(
    //     MAKE_BLAST_FASTA.out.blastn_contigs_fasta,
    //     ch_diamond_nr_db,
    //     params.diamond_output_format,
    //     ''
    // )
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
