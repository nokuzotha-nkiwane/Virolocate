# Virolocate

## Introduction

**Virolocate** is a Nextflow pipeline that processes metatranscriptomic reads to identify potential novel viruses.

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/guidelines/graphic_design/workflow_diagrams#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))2. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))

## Documentation

The documentation for the pipeline can be accessed at [https://nokuzotha-nkiwane.github.io/Virolocate/](https://nokuzotha-nkiwane.github.io/Virolocate/usage.html)

## Testing

A built-in test profile is available in the Virolocate pipeline. This profile can be used to assess the Virolocat infrastructure using the `test` profile option. This allows users to address infrastructural issues before performin analyses.

**NOTE** the test instructions below assume that you have have eith `docker` or `singularity` on server or machine you plan to test the pipeline. For other institutional configs please visit [nf-core/configs](https://nf-co.re/docs/usage/getting_started/configuration#different-config-locations).

```
$ nextflow run nokuzotha-nkiwane/Virolocate \
  -profile test,docker --outdir test_output
```

```
$ nextflow run nokuzotha-nkiwane/Virolocate \
  -profile test,singularity --outdir test_output
```

## Credits

Virolocate was originally written by Nokuzotha Nkiwane, Abhinav Sharma, Tomasz J. Sanko and Eduan Wilkinson.


<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use CERI-KRISP/virolocate_nf for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->



This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
