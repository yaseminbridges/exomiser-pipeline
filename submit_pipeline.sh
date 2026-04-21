#!/bin/bash
set -euo pipefail

source /etc/profile.d/modules.sh
module load java/23.0.1
module load nextflow/25.04.6-with-plugins

export NXF_OFFLINE='true'

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
mkdir -p "$WORK_DIR/logs"

nextflow run "$SCRIPT_DIR/main.nf" \
    --batch_dir     "$BATCH_DIR" \
    --exomiser_jar  "$EXOMISER_JAR" \
    --spring_config "$SPRING_CONFIG" \
    --results_dir   "$RESULTS_DIR" \
    "$@" \
    |& tee "$WORK_DIR/logs/nextflow.log"
