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

| Parameter                | Default Value | Description                                                                                                                                                                                                        |
|--------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `FIXME`       | FIXME            | FIXME                                                                                                                                                                  |
| `FIXME`       | FIXME            | FIXME                                                                                                                                                                  |
| `FIXME`       | FIXME            | FIXME                                                                                                                                                                  |
| `FIXME`       | FIXME            | FIXME                                                                                                                                                                  |
| `FIXME`       | FIXME            | FIXME                                                                                                                                                                  |

---

## Skipping Pipeline Steps

| Parameter         | Default Value | Description                                                                     |
|-------------------|---------------|---------------------------------------------------------------------------------|
| `skip_FIXME` | `FIXME`       |                      |

> 💡 **Hint**: Use these flags to customize the pipeline execution based on your specific requirements.

---

## Reference Files

| Parameter   | Default Value | Description                 |
|-------------|---------------|-----------------------------|
| `ref_FIXME` | `FIXME`       | Path to the FIXME |

> ⚠️ **Warning**: It is recommended to use the provided reference files to ensure compatibility.

---

