#!/bin/bash

SCRIPT_DIR="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/pipeline/with_pheval"

# ── Configuration ─────────────────────────────────────────────────────────────

# Edit these paths before running
JOB_ID=""   # change this per run — used for log directory

PHENOPACKET_DIR=""
EXOMISER_JAR="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/configurations/exomiser-15.0.0/2512/model_1/exomiser-cli-15.0.0-RC5/exomiser-cli-15.0.0-RC5.jar"
SPRING_CONFIG="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/configurations/exomiser-15.0.0/2512/model_1/application.properties"
RESULTS_DIR="/re_gecip/enhanced_interpretation/ybridges/100KGP_phenopackets/main_programme/results"
PHEVAL_EXOMISER_IMAGE="/re_gecip/enhanced_interpretation/ubridges/100KGP_phenopackets/pipeline/pheval-exomiser.sif"
PHEVAL_OUTPUT_DIR=""
SCORE_NAME=""
MAX_JOBS=0              # lines per batch file — 0 = no split (one file), 10 or 20 = run in parallel chunks
EXOMISER_VERSION="15.0.0"
SORT_ORDER="descending"
VARIANT_ANALYSIS=true
GENE_ANALYSIS=true
DISEASE_ANALYSIS=false
OUTPUT_FORMATS="JSON,TSV_GENE,TSV_VARIANT,HTML,PARQUET,VCF"
ANALYSIS_YAML=""
VCF_DIR=""              # optional: path to VCF directory, set to /none to use path in phenopacket

# ── Run ───────────────────────────────────────────────────────────────────────

mkdir -p "nextflow_logs/${JOB_ID}/logs"

WORK_DIR="$(pwd)/nextflow_logs/${JOB_ID}"
cd "$WORK_DIR" || exit 1
export PHENOPACKET_DIR EXOMISER_JAR SPRING_CONFIG RESULTS_DIR PHEVAL_EXOMISER_IMAGE PHEVAL_OUTPUT_DIR \
       SCORE_NAME MAX_JOBS EXOMISER_VERSION SORT_ORDER VARIANT_ANALYSIS GENE_ANALYSIS DISEASE_ANALYSIS \
       ANALYSIS_YAML VCF_DIR OUTPUT_FORMATS WORK_DIR

bsub -q long \
     -P re_gecip_enhanced_interpretation \
     -M 1000 \
     -R "rusage[mem=1000] span[hosts=1]" \
     -n 1 \
     -J "nf_pheval_${JOB_ID}" \
     -o "$WORK_DIR/logs/nextflow.txt" \
     -e "$WORK_DIR/logs/nextflow.err" \
     bash "$SCRIPT_DIR/submit_pipeline.sh"

echo ""
echo "Pipeline submitted. To check progress:"
echo "  bjobs                                   # check all submitted jobs"
echo "  bkill -J nf_pheval_${JOB_ID}           # stop the pipeline"
