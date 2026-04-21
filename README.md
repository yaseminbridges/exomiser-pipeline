# Exomiser Nextflow Pipeline

Runs a directory of Exomiser batch files on an LSF cluster via `bsub`, one job per file.

## Requirements

- Nextflow >= 22.10
- Access to an LSF cluster
- `java/23.0.1` module available on the cluster

## Usage

```bash
nextflow run main.nf \
  --batch_dir     /re_gecip/.../100KGP_phenopackets/batch_files \
  --exomiser_jar  /re_gecip/.../exomiser-cli-15.0.0-RC5/exomiser-cli-15.0.0-RC5.jar \
  --spring_config /re_gecip/.../exomiser-15.0.0/2512/model_1/application.properties \
  --results_dir   /re_gecip/.../results
```

### All parameters

| Parameter         | Required | Default                            | Description                             |
|-------------------|----------|------------------------------------|-----------------------------------------|
| `--batch_dir`     | yes      | —                                  | Directory containing batch files        |
| `--exomiser_jar`  | yes      | —                                  | Path to the Exomiser 15 CLI jar         |
| `--spring_config` | yes      | —                                  | Path to `application.properties`        |
| `--results_dir`   | yes      | —                                  | Directory where Exomiser writes its output files |
| `--chmod`         | no       | `g+rw`                             | Permission string applied to all output dirs on completion |
| `--short_queue`   | no       | `short`                            | LSF queue name                          |
| `--project`       | no       | `re_gecip_enhanced_interpretation` | LSF project (`-P`)                      |
| `--java_module`   | no       | `java/23.0.1`                      | Environment module to load              |

All `.txt` files in `--batch_dir` are picked up automatically, one job per file.

### Running without keeping the terminal open

Since the pipeline may run for a long time, use `screen` so it keeps running after
you disconnect from your Amazon Workspace:

```bash
# Set your paths
export BATCH_DIR=/re_gecip/.../batch_files
export EXOMISER_JAR=/re_gecip/.../exomiser-cli-15.0.0-RC5.jar
export SPRING_CONFIG=/re_gecip/.../application.properties
export RESULTS_DIR=/re_gecip/.../results

# Start a named screen session and launch the pipeline
screen -S exomiser bash submit_pipeline.sh
```

Detach at any time with `Ctrl+A` then `D` — the pipeline keeps running.

To reconnect later:
```bash
screen -r exomiser
```

To check progress without reattaching:
```bash
tail -f logs/nextflow.log
bjobs                        # see all submitted Exomiser jobs
```

### Resume after failure

If the pipeline is interrupted, reattach or start a new screen session and add `-resume`:

```bash
screen -S exomiser bash submit_pipeline.sh -resume
```

## What gets submitted to LSF

Nextflow manages all bsub scripts internally. For each batch file (e.g. `sample_batch.yml`)
it creates a hashed work directory and submits a script that looks like this:

```bash
#!/bin/bash
#BSUB -q short
#BSUB -P re_gecip_enhanced_interpretation
#BSUB -R "rusage[mem=8000]"
#BSUB -R "span[hosts=1]"
#BSUB -M 8000
#BSUB -n 1
#BSUB -J nf-RUN_EXOMISER-(sample_batch.yml)
#BSUB -o /path/to/work/3f/a1b2c3.command.log
#BSUB -e /path/to/work/3f/a1b2c3.command.err

module load java/23.0.1

java \
    -Xmx7g \
    -Dspring.config.location=/re_gecip/.../application.properties \
    -jar /re_gecip/.../exomiser-cli-15.0.0-RC5.jar \
    batch sample_batch.yml
```

Note: `-o` / `-e` point into Nextflow's `work/` directory rather than a named file
alongside your batch file. Use the trace report (see below) to map job names back to
input files.

## Timeout retry behaviour

Jobs that are killed by LSF due to exceeding the queue wall-clock limit
(exit code 140 `TERM_RUNLIMIT` or 130) are automatically resubmitted to the
**same short queue** up to **3 times**. If a job still fails after 3 retries it
is marked as failed and the pipeline continues with remaining jobs.

## Output and logs

After the run, `reports/` contains:

| File                        | Contents                                         |
|-----------------------------|--------------------------------------------------|
| `exomiser_report.html`      | Interactive summary of all tasks                 |
| `exomiser_timeline.html`    | Wall-clock timeline per job                      |
| `exomiser_trace.txt`        | Tab-separated table: task, status, exit code, queue, memory, duration |

Exomiser's own output files are written wherever your batch file specifies
(`outputDirectory` / `outputFileName` inside each batch YAML).

### Finding logs for a specific job

```bash
# See all tasks and their work directories
grep "sample_batch" reports/exomiser_trace.txt

# Or look directly in the work directory
cat work/3f/a1b2c3.../.command.log
cat work/3f/a1b2c3.../.command.err
```
