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
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_virolocate-nf_pipeline'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'

// import local modules
include { NCBI_PROCESSING } from '../modules/local/ncbi_processing.nf'
include { RVDB_PROCESSING } from '../modules/local/rvdb_processing.nf'
include { TAXONOMY_ID    } from '../modules/local/taxonomy_id.nf'
include { CONTIG_FILTER } from '../modules/local/contig_filter.nf'
include { CONTIG_UNIQUE_SORTER } from '../modules/local/sorter.nf'
include { MAKE_BLASTN_FASTA } from '../modules/local/make_blastn_fasta.nf'
include { FETCH_METADATA } from '../modules/local/metadata.nf'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
params.samplesheet = '../disc_pipe/s_sheet.csv'
ch_samplesheet = Channel.fromPath(params.samplesheet)

workflow VIROLOCATE_NF {
    
    ch_samplesheet = Channel.fromPath(params.samplesheet)
    //take input data
    take:
        ch_samplesheet 
    
    //main starts main workflow logic
    //ch_versions will collect software version info form each tool
    //ch_multiqc_files will collect quality control reports for final aggregation
    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    
    //Parse samplesheet to get reads
    //assumes paired end readsa as default
    ch_reads = ch_samplesheet
        .splitCsv(header: true)
        .map { row ->
            def meta = [:]
            meta.id = row.sample
            meta.single_end = false 
            
            def reads = []
            if (row.fastq_1 && row.fastq_2) {
                reads = [file(row.fastq_1), file(row.fastq_2)]
            } else if (row.fastq_1) {
                reads = [file(row.fastq_1)]
                meta.single_end = true
            }
            
            return [meta, reads]
        }

    // MODULE: Run FastQC
    
    FASTQC_PRE (ch_reads)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_PRE.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC_PRE.out.versions.first())

    //---------------------------------------

    //Trimmomatic run to trim reads
    //TODO: @nox Add a parameter to allow users to pass the folder location
    // Assuming fastq is a list of files [R1, R2] for paired-end
    
    // ch_reads = ch_samplesheet.map { meta, fastq -> [meta, fastq] }
    
    TRIMMOMATIC(ch_reads, params.trimmomatic_adapters,'')
    ch_versions = ch_versions.mix(TRIMMOMATIC.out.versions.first())

    //FastQC to check quality of trimmed reads
    FASTQC_POST(TRIMMOMATIC.out.trimmed_reads)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_POST.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC_POST.out.versions.first())

    //Megahit to assemble reads into contigs
    //TODO: @nox we need to transform the shape of TRIMMOMATIC.out.trimmed_reads
    //such that it aligns with the expectation of MEGAHIT
    
    // ch_megahit_paired_input = TRIMMOMATIC.out.trimmed_reads.map { meta, reads -> [meta, reads] }
    MEGAHIT(TRIMMOMATIC.out.trimmed_reads, '')
    ch_versions = ch_versions.mix(MEGAHIT.out.versions.first())

    //Diamond make_db to create diamond formatted rvdb and ncbi databases
    ch_rvdb_fasta = Channel.fromPath(params.rvdb_fasta, checkIfExists: true)
        .map { fasta -> [[id: 'rvdb'], fasta] }
    DIAMOND_MAKE_RVDB(ch_rvdb_fasta, '')
    ch_versions = ch_versions.mix(DIAMOND_MAKE_RVDB.out.versions.first())

    ch_ncbi_fasta = Channel.fromPath(params.ncbi_fasta, checkIfExists: true)
        .map { fasta -> [[id: 'ncbi'], fasta] }
    DIAMOND_MAKE_NCBI_DB(ch_ncbi_fasta, '')
    ch_versions = ch_versions.mix(DIAMOND_MAKE_NCBI_DB.out.versions.first())


    //Diamond to compare read proteins against known proteins in databases
    // NOTE: In the bash script, we have the output extension as `m8` which is
    // just a TSV, therefore we shall use TSV directly to call the nf-core module.
    //TODO: @nox we need to add more parameters to this process-call
    
    //are these channels structured correctly to catch dmnd dbs made by diamond make_db
    ch_diamond_rvdb_db = (DIAMOND_MAKE_RVDB.out.db).map { meta, db -> db }
    ch_diamond_ncbi_db = (DIAMOND_MAKE_NCBI_DB.out.db).map { meta, db -> db }
    // ch_diamond_input = (MEGAHIT.out.contigs).map { meta, contigs, db -> [meta, contigs] }

    DIAMOND_BLASTX_PRE_RVDB(
        MEGAHIT.out.contigs,
        ch_diamond_rvdb_db,
        params.diamond_output_format,
        ''
    )
    
    ch_versions = ch_versions.mix(DIAMOND_BLASTX_PRE_RVDB.out.versions.first())

     DIAMOND_BLASTX_PRE_NCBI(
        MEGAHIT.out.contigs,
        ch_diamond_ncbi_db,
        params.diamond_output_format,
        ''  
    )
    
    ch_versions = ch_versions.mix(DIAMOND_BLASTX_PRE_NCBI.out.versions.first())

    //get accession ids and taxonomy ids for taxonkit to use
    RVDB_PROCESSING(DIAMOND_BLASTX_PRE_NCBI.out.tsv)
    ch_versions = ch_versions.mix(RVDB_PROCESSING.out.versions.first())

    NCBI_PROCESSING(DIAMOND_BLASTX_PRE_RVDB.out.tsv)
    ch_versions = ch_versions.mix(NCBI_PROCESSING.out.versions.first())

    //get accession ids and taxonomy ids for taxonkit to use
    TAXONOMY_ID(RVDB_PROCESSING.out.rvdb_fin_acc, NCBI_PROCESSING.out.ncbi_fin_acc)
    ch_versions = ch_versions.mix(TAXONOMY_ID.out.versions.first())

    //Taxonkit for lineage filtering and getting taxonomy ids
    ch_taxonkit_db = Channel.fromPath(params.taxonkit_db, checkIfExists: true)
    TAXONKIT_LINEAGE(TAXONOMY_ID.out.tsv, ch_taxonkit_db, '')
    ch_versions = ch_versions.mix(TAXONKIT_LINEAGE.out.versions.first())

    //Contig_filter to extract sequences marked as viral only
    CONTIG_FILTER(TAXONKIT_LINEAGE.out.tsv)
    ch_versions = ch_versions.mix(CONTIG_FILTER.out.versions.first())

    //sort the filtered list to remove duplicates
    CONTIG_UNIQUE_SORTER(CONTIG_FILTER.out.viral_contigs_metadata)
    ch_versions = ch_versions.mix(CONTIG_UNIQUE_SORTER.out.versions.first())

    //make fasta file to blastn against NT 
    MAKE_BLASTN_FASTA(CONTIG_UNIQUE_SORTER.out.viral_contig_list)
    ch_versions = ch_versions.mix(MAKE_BLASTN_FASTA.out.versions.first())

    //Blastn for comparing contig sequences to known nucleotide sequences
    ch_blastn_db = Channel.fromPath("${params.blastn_db}*", checkIfExists: true).collect()
    BLAST_BLASTN(MAKE_BLASTN_FASTA.out.blastn_contigs_fasta, ch_blastn_db, '')
    ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions.first())

    //get metadata of the blastn hits
    FETCH_METADATA(BLAST_BLASTN.out.tsv)
    ch_versions = ch_versions.mix(FETCH_METADATA.out.versions.first())

    //Make nr database using nr fasta
    ch_nr_fasta = Channel.fromPath(params.blastx_nr_fasta, checkIfExists: true)
        .map { fasta -> [[id: 'nr'], fasta] }
    DIAMOND_MAKE_NR_DB(ch_nr_fasta, '')
    ch_versions = ch_versions.mix(DIAMOND_MAKE_NR_DB.out.versions.first())

    //Blastx to compare proteins to check for distant orthologs
    ch_diamond_nr_db = DIAMOND_MAKE_NR_DB.out.db.map { meta, db -> db }
    DIAMOND_BLASTX_FINAL(
        MAKE_BLASTN_FASTA.out.blastn_contigs_fasta,
        ch_diamond_nr_db,
        params.diamond_output_format,
        ''
    )
    ch_versions = ch_versions.mix(DIAMOND_BLASTX_FINAL.out.versions.first())

    //get metadata of the blastx hits
    FETCH_METADATA(DIAMOND_BLASTX_FINAL.out.tsv)
    ch_versions = ch_versions.mix(FETCH_METADATA.out.versions.first())


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
