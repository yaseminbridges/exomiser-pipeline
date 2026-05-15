#!/bin/bash
# ── Configuration ─────────────────────────────────────────────────────────────
SCRIPT_DIR="/re_gecip/enhanced_interpretation/ubridges/100KGP_phenopackets/pipeline"
# Edit these paths before running

JOB_ID=""   # change this per run — used for log directory

BATCH_DIR="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/batch_files"
EXOMISER_JAR="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/configurations/exomiser-15.0.0/2512/model_1/exomiser-cli-15.0.0-RC5/exomiser-cli-15.0.0-RC5.jar"
SPRING_CONFIG="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/configurations/exomiser-15.0.0/2512/model_1/application.properties"
RESULTS_DIR="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/results"

# ── Run ───────────────────────────────────────────────────────────────────────

mkdir -p "nextflow_logs/${JOB_ID}/logs"

WORK_DIR="$(pwd)/nextflow_logs/${JOB_ID}"
cd "$WORK_DIR" || exit 1
export BATCH_DIR EXOMISER_JAR SPRING_CONFIG RESULTS_DIR WORK_DIR

bsub -q long \
     -P re_gecip_enhanced_interpretation \
     -M 1000 \
     -R "rusage[mem=1000] span[hosts=1]" \
     -n 1 \
     -J "nf_exomiser_${JOB_ID}" \
     -o "$WORK_DIR/logs/nextflow.txt" \
     -e "$WORK_DIR/logs/nextflow.err" \
     bash "$SCRIPT_DIR/submit_pipeline.sh"

echo ""
echo "Pipeline submitted. To check progress:"
echo "  bjobs                                   # check all submitted jobs"
echo "  bkill -J nf_exomiser_${JOB_ID}         # stop the pipeline"