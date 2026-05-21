# Exomiser + PhEval Nextflow Pipeline

Runs a three-stage pipeline on an LSF cluster:

1. **Prepare** — uses the `pheval-exomiser` Singularity image to generate Exomiser batch files from a phenopacket directory
2. **Run** — submits one LSF job per batch file to run Exomiser with Java
3. **Post-process** — uses the `pheval-exomiser` Singularity image to standardise Exomiser results into PhEval outputs

## Requirements

- Nextflow 25.04.6
- Singularity 4.1.1
- Access to an LSF cluster
- `java/23.0.1` module available on the cluster
- `pheval-exomiser.sif` Singularity image (see [Building the image](#building-the-image))

## Building the image

Navigate to the directory where you want the `.sif` file to be saved, then run:

```bash
singularity pull pheval-exomiser.sif docker://docker-remote.artifactory.aws.gel.ac/yaseminbridges/pheval-exomiser:latest
```

The `.sif` file will be created in that directory. Update `PHEVAL_EXOMISER_IMAGE` in `run.sh` to point to its full path.

## Usage

Edit the configuration section of `run.sh` and run:

```bash
bash run.sh
```

### Configuration (`run.sh`)

| Variable | Required | Description                                                                                     |
|---|---|-------------------------------------------------------------------------------------------------|
| `JOB_ID` | yes | Unique identifier for this run — used for the log directory                                     |
| `PHENOPACKET_DIR` | yes | Directory containing input phenopackets                                                         |
| `EXOMISER_JAR` | yes | Path to the Exomiser CLI jar                                                                    |
| `SPRING_CONFIG` | yes | Path to `application.properties`                                                                |
| `RESULTS_DIR` | yes | Directory where Exomiser writes its raw output                                                  |
| `PHEVAL_EXOMISER_IMAGE` | yes | Path to the `pheval-exomiser.sif` Singularity image                                             |
| `PHEVAL_OUTPUT_DIR` | yes | Directory for standardised PhEval outputs — can be the same as `RESULTS_DIR`                    |
| `SCORE_NAME` | yes | Score column to rank by (e.g. `geneCombinedScore`)                                              |
| `MAX_JOBS` | no | Lines per batch file — `0` = no split, `10`/`20` = parallel chunks (default: `0`)               |
| `EXOMISER_VERSION` | no | Exomiser version string (default: `15.0.0`)                                                     |
| `SORT_ORDER` | no | `ascending` or `descending` (default: `descending`)                                             |
| `VARIANT_ANALYSIS` | no | Create PhEval variant results (default: `true`)                                                 |
| `GENE_ANALYSIS` | no | Create PhEval gene results (default: `true`)                                                    |
| `DISEASE_ANALYSIS` | no | Create PhEval disease results (default: `false`)                                                |
| `OUTPUT_FORMATS` | no | Comma-separated Exomiser output formats (default: `JSON,TSV_GENE,TSV_VARIANT,HTML,PARQUET,VCF`) |
| `ANALYSIS_YAML` | yes | Path to the Exomiser analysis `.yml` file                                                       |
| `VCF_DIR` | yes | Path to VCF directory for variant analysis                                                      |

### Parallel batching

Set `MAX_JOBS` to split the phenopackets into smaller batch files, each running as a separate parallel LSF job:

```bash
MAX_JOBS=20   # each batch file contains 20 phenopackets
```

## Output

### PhEval standardised results (`PHEVAL_OUTPUT_DIR`)

| Directory | Contents |
|---|---|
| `pheval_gene_results/` | Standardised gene ranking results |
| `pheval_variant_results/` | Standardised variant ranking results |
| `pheval_disease_results/` | Standardised disease ranking results (if enabled) |

### Pipeline reports (`reports/`)

| File | Contents |
|---|---|
| `exomiser_pheval_report.html` | Interactive summary of all tasks |
| `exomiser_pheval_timeline.html` | Wall-clock timeline per job |
| `exomiser_pheval_trace.txt` | Tab-separated table: task, status, exit code, queue, memory, duration |

## Monitoring

```bash
bjobs                             # all submitted jobs
tail -f nextflow_logs/<JOB_ID>/logs/nextflow.txt   # follow Nextflow log
bkill -J nf_pheval_<JOB_ID>      # stop the pipeline
```

## Resume after failure

Set the same `JOB_ID` in `run.sh` and rerun — `-resume` is always on, so completed tasks are skipped.
