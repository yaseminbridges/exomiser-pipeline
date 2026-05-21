#!/bin/bash
set -euo pipefail

source /etc/profile.d/modules.sh
module load nextflow/25.04.6-with-plugins

export NXF_OFFLINE='true'

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
mkdir -p "$WORK_DIR/logs"

nextflow run "$SCRIPT_DIR/main.nf" \
    -resume \
    --phenopacket_dir   "$PHENOPACKET_DIR" \
    --exomiser_jar      "$EXOMISER_JAR" \
    --spring_config     "$SPRING_CONFIG" \
    --results_dir       "$RESULTS_DIR" \
    --pheval_exomiser_image      "$PHEVAL_EXOMISER_IMAGE" \
    --pheval_output_dir "$PHEVAL_OUTPUT_DIR" \
    --score_name        "$SCORE_NAME" \
    --max_jobs          "$MAX_JOBS" \
    --exomiser_version  "$EXOMISER_VERSION" \
    --sort_order        "$SORT_ORDER" \
    --variant_analysis  "$VARIANT_ANALYSIS" \
    --gene_analysis     "$GENE_ANALYSIS" \
    --disease_analysis  "$DISEASE_ANALYSIS" \
    --output_formats    "$OUTPUT_FORMATS" \
    --analysis_yaml     "$ANALYSIS_YAML" \
    --vcf_dir           "$VCF_DIR" \
    "$@"
