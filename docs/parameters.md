# Parameters

This document provides an overview of the customizable parameters for the Virolocate pipeline. Each parameter is listed with its default value, description.

> 💡 **Hint**: you may check a full parameters [reference file](https://github.com/nokuzotha-nkiwane/Virolocate/blob/master/nextflow.config).

---

## Common Parameters

### Input Samplesheet
| Parameter             | Default Value              | Description                                                                                     |
|-----------------------|----------------------------|-------------------------------------------------------------------------------------------------|
| `input`   | `null`  | The input CSV file containing sample information.    |

> 💡 **Hint**: The samplesheet should include the columns `[sample,fastq_1,fastq_2]`.

---

### Output Directory
| Parameter   | Default Value         | Description                                                                 |
|-------------|-----------------------|-----------------------------------------------------------------------------|
| `outdir`    | `null`     | The directory where all output files will be written.                      |


---

## Quality Control Parameters

> ⚠️ **Attention**: Ensure these values are adjusted based on the quality of your input data to avoid processing errors.
> The defaults are set to faciliate a majority of users. Only advanced users are recommended to change these.

### Trimmomatic

| Parameter                | Default Value | Description                                                                                                                                                                                                        |
|--------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ILLUMINACLIP`       | fastaWithAdaptersEtc : seed mismatches : palindrome clip threshold : simple clip threshold            | cut adapter and other illumina-specific sequences from the read                                                                                                                                                                  |
| `<fastaWithAdaptersEtc>`       | ${params.trimmomatic_adapters}$            | specifies the path to a fasta file containing all the adapters, PCR sequences etc                                                                                                                                                                  |
| `<seed mismatches>`       | 2            | specifies the maximum mismatch count which will still allow a full match to be performed                                                                                                                                                                  |
| `<palindrome clip threshold>`       | 30            | specifies how accurate the match between the two 'adapter ligated' reads must be for PE palindrome read alignment                                                                                                                                                                  |
| `<simple clip threshold>`       | 10            | specifies how accurate the match between any adapter etc. sequence must be against a read                                                                                                                                                                  |
| `LEADING`       | 5            | cut bases off the start of a read, if below a threshold quality                                                                                                                                                                  |
| `TRAILING`       | 5            | cut bases off the end of a read, if below a threshold quality                                                                                                                                                                  |
| `SLIDINGWINDOW`       | 4:15            | perform a sliding window trimming, cutting once the average quality within the window falls below a threshold                                                                                                                                                                  |
| `MINLEN`       | 25            | drop the read if it is below a specified length                                                                                                                                                                  |
| `MINLEN`       | 25            | drop the read if it is below a specified length                                                                                                                                                                  |

### Diamond Blastx Pre

| Parameter                | Default Value | Description                                                                                                                                                                                                        |
|--------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `--evalue`       | 1e-5            | maximum e-value to report alignments                                                                                                                                                                  |
| `--outfmt`       | '6 qseqid qlen sseqid stitle pident length evalue bitscore            | output format                                                                                                                                                                  |
| `--id`       | 80            | minimum identity% to report an alignment                                                                                                                                                                  |
| `--strand`       | both            | query strands to search (both/minus/plus)                                                                                                                                                                  |
| `--unal`       | 0            | report unaligned queries (0=no, 1=yes)                                                                                                                                                                  |

### Diamond Blastx Final (replaces `--outfmt` above)

| Parameter                | Default Value | Description                                                                                                                                                                                                        |
|--------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `--outfmt`       | '6 qseqid sseqid qlen stitle pident length qstart qend evalue bitscore            | output format                                                                                                                                                                  |

### Blast Blastn

| Parameter                | Default Value | Description                                                                                                                                                                                                        |
|--------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `--evalue`       | 1e-5            | maximum e-value to report alignments                                                                                                                                                                  |
| `--max_target_seqs`       | 20            | Maximum number of aligned sequences to keep                                                                                                                                                                   |
| `--outfmt`       | '6 qseqid sseqid qlen stitle pident length qstart qend evalue bitscore            | output format                                                                                                                                                                  |

### Lineage Pre

| Parameter                | Default Value | Description                                                                                                                                                                                                        |
|--------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `-i`       | 9            | field index of taxid. input data should be tab-separated                                                                                                                                                                  |
| `-d`       | $'\t'            | field delimiter in lineage (default ";")                                                                                                                                                                  |

### Lineage Blastx & Lineage Blastn

| Parameter                | Default Value | Description                                                                                                                                                                                                        |
|--------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `-i`       | 10            | field index of taxid. input data should be tab-separated                                                                                                                                                                  |
| `-d`       | $'\t'            | field delimiter in lineage (default ";")                                                                                                                                                                  |
---

## Skipping Pipeline Steps

| Parameter         | Default Value | Description                                                                     |
|-------------------|---------------|---------------------------------------------------------------------------------|
| `null` | `null`       |                      |

> 💡 **Hint**: Use these flags to customize the pipeline execution based on your specific requirements.

---

## Reference Files

| Parameter   | Default Value | Description                 |
|-------------|---------------|-----------------------------|
| `rvdb_fasta` | `null`       | Path to the RVDB unclustered protein fasta |
| `ncbi_nr_fasta` | `null`       | Path to the full NCBI non-redundant protein (Nr) database in fasta format |
| `ncbi_nt_db` | `null`       | Path to the full NCBI nucleotide (NT) |
| `viral_csv` | `null`       | Path to the csv used to subset NCBI NR database to viral fasta sequences only |
| `ncbi_viral_fasta` | `null`       | Path to the subset NCBI NR database |
| `taxdb` | `null`       | Path to the Taxdump database from TaxonKit |

> ⚠️ **Warning**: It is recommended to use the provided reference files to ensure compatibility.

---

