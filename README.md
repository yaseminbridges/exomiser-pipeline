# Exomiser Nextflow Pipeline

Runs a directory of Exomiser batch files on an LSF cluster via `bsub`, one job per file.

## Requirements

- Nextflow 25.04.6
- Access to an LSF cluster
- `java/23.0.1` module available on the cluster

## Usage

Edit the configuration section of `run.sh` and run:

```bash
bash run.sh
```

The Nextflow head process is submitted to the `long` LSF queue so it stays alive for the duration of the run.

### Configuration (`run.sh`)

| Variable        | Required | Description                                      |
|-----------------|----------|--------------------------------------------------|
| `JOB_ID`        | yes      | Unique identifier for this run — used for the log directory |
| `BATCH_DIR`     | yes      | Directory containing `.txt` batch files          |
| `EXOMISER_JAR`  | yes      | Path to the Exomiser 15 CLI jar                  |
| `SPRING_CONFIG` | yes      | Path to `application.properties`                 |
| `RESULTS_DIR`   | yes      | Directory where Exomiser writes its output files |

### All Nextflow parameters

| Parameter       | Required | Default                            | Description                             |
|-----------------|----------|------------------------------------|-----------------------------------------|
| `--batch_dir`   | yes      | —                                  | Directory containing batch files        |
| `--exomiser_jar`| yes      | —                                  | Path to the Exomiser 15 CLI jar         |
| `--spring_config`| yes     | —                                  | Path to `application.properties`        |
| `--results_dir` | yes      | —                                  | Directory where Exomiser writes its output files |
| `--chmod`       | no       | `g+rwx`                            | Permission string applied to output dirs on completion |
| `--short_queue` | no       | `short`                            | LSF queue name for Exomiser jobs        |
| `--project`     | no       | `re_gecip_enhanced_interpretation` | LSF project (`-P`)                      |
| `--java_module` | no       | `java/23.0.1`                      | Environment module to load              |

All `.txt` files in `--batch_dir` are picked up automatically, one job per file.

## Monitoring

```bash
bjobs                                                    # check all submitted jobs
tail -f nextflow_logs/<JOB_ID>/logs/nextflow.txt         # follow Nextflow log
bkill -J nf_exomiser_<JOB_ID>                           # stop the pipeline
```

## Resume after failure

Set the same `JOB_ID` in `run.sh` and rerun — `-resume` is always on, so completed tasks are skipped and the log is appended to.

## What gets submitted to LSF

Nextflow manages all bsub scripts internally. For each batch file (e.g. `sample_batch.txt`)
it creates a hashed work directory and submits a script that looks like this:

```bash
#!/bin/bash
#BSUB -q short
#BSUB -P re_gecip_enhanced_interpretation
#BSUB -R "rusage[mem=8000]"
#BSUB -R "span[hosts=1]"
#BSUB -M 8000
#BSUB -n 1
#BSUB -J nf-RUN_EXOMISER-(sample_batch.txt)
#BSUB -o /path/to/work/3f/a1b2c3.command.log
#BSUB -e /path/to/work/3f/a1b2c3.command.err

module load java/23.0.1

java \
    -Xmx7g \
    -Dspring.config.location=/re_gecip/.../application.properties \
    -jar /re_gecip/.../exomiser-cli-15.0.0-RC5.jar \
    batch sample_batch.txt
```

Note: `-o` / `-e` point into Nextflow's `work/` directory rather than a named file
alongside your batch file. Use the trace report (see below) to map job names back to
input files.

## Timeout retry behaviour

Jobs that are killed by LSF due to exceeding the queue wall-clock limit
(exit code 140 `TERM_RUNLIMIT` or 130) are automatically resubmitted up to **3 times**.
If a job still fails after 3 retries it is marked as failed and the pipeline continues
with remaining jobs.

## Output and logs

After the run, `nextflow_logs/<JOB_ID>/reports/` contains:

| File                        | Contents                                                               |
|-----------------------------|------------------------------------------------------------------------|
| `exomiser_report.html`      | Interactive summary of all tasks                                       |
| `exomiser_timeline.html`    | Wall-clock timeline per job                                            |
| `exomiser_trace.txt`        | Tab-separated table: task, status, exit code, queue, memory, duration  |

Exomiser's own output files are written wherever your batch file specifies
(`outputDirectory` / `outputFileName` inside each batch YAML).

### Finding logs for a specific job

```bash
# See all tasks and their work directories
grep "sample_batch" nextflow_logs/<JOB_ID>/reports/exomiser_trace.txt

# Or look directly in the work directory
cat work/3f/a1b2c3.../.command.log
cat work/3f/a1b2c3.../.command.err
```
