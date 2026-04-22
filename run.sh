#!/bin/bash
# ── Configuration ─────────────────────────────────────────────────────────────
# Edit these paths before running

JOB_ID=""   # change this per run — used for screen name and log directory

BATCH_DIR="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/batch_files"
EXOMISER_JAR="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/configurations/exomiser-15.0.0/2512/model_1/exomiser-cli-15.0.0-RC5/exomiser-cli-15.0.0-RC5.jar"
SPRING_CONFIG="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/configurations/exomiser-15.0.0/2512/model_1/application.properties"
RESULTS_DIR="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/results"

# ── Run ───────────────────────────────────────────────────────────────────────

mkdir -p "logs/${JOB_ID}"

WORK_DIR="$(pwd)/logs/${JOB_ID}"
cd "$WORK_DIR"
export BATCH_DIR EXOMISER_JAR SPRING_CONFIG RESULTS_DIR WORK_DIR

screen -S "exomiser_${JOB_ID}" -d -m bash submit_pipeline.sh

echo ""
echo "Pipeline submitted. To check progress:"
echo "  screen -r exomiser_${JOB_ID}          # attach to session"
echo "  tail -f logs/${JOB_ID}/nextflow.log    # follow log"
echo "  bjobs                                  # check submitted jobs"