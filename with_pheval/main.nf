nextflow.enable.dsl=2

params.phenopacket_dir      = null
params.exomiser_jar         = null
params.spring_config        = null
params.results_dir          = null
params.pheval_exomiser_image         = null   // path to pheval-exomiser .sif file
params.pheval_output_dir    = null
params.score_name           = null

// prepare-exomiser-batch options
params.analysis_yaml        = null
params.vcf_dir              = null
params.exomiser_version     = "15.0.0"
params.batch_prefix         = "RUN"
params.max_jobs             = 0
params.variant_analysis     = false
params.output_formats       = ""

// post-process-exomiser-results options
params.sort_order           = "descending"
params.gene_analysis        = false
params.disease_analysis     = false

params.chmod                = "g+rwx"

if (!params.phenopacket_dir)   error "Please provide --phenopacket_dir"
if (!params.exomiser_jar)      error "Please provide --exomiser_jar"
if (!params.spring_config)     error "Please provide --spring_config"
if (!params.results_dir)       error "Please provide --results_dir"
if (!params.pheval_exomiser_image)      error "Please provide --pheval_exomiser_image"
if (!params.pheval_output_dir) error "Please provide --pheval_output_dir"
if (!params.score_name)        error "Please provide --score_name"
if (!params.analysis_yaml)     error "Please provide --analysis_yaml"
if (!params.vcf_dir)           error "Please provide --vcf_dir"

process PREPARE_BATCHES {
    container params.pheval_exomiser_image

    output:
    path "tool_input_commands/*.txt"

    script:
    def variant_flag  = params.variant_analysis ? "--variant-analysis" : ""
    def formats       = params.output_formats ? params.output_formats.tokenize(",").collect { "--output-formats ${it.trim()}" }.join(" \\\n        ") : ""
    """
    pheval-exomiser prepare-exomiser-batch \\
        --phenopacket-dir ${params.phenopacket_dir} \\
        --output-dir . \\
        --results-dir ${params.results_dir} \\
        --exomiser-version ${params.exomiser_version} \\
        --batch-prefix ${params.batch_prefix} \\
        --max-jobs ${params.max_jobs} \\
        --analysis-yaml ${params.analysis_yaml} \\
        --vcf-dir ${params.vcf_dir} \\
        ${formats} \\
        ${variant_flag}
    """
}

process RUN_EXOMISER {
    tag "$batch_file.name"

    errorStrategy 'retry'
    maxRetries 3

    input:
    path batch_file

    output:
    val true

    script:
    """
    java \\
        -Xmx7g \\
        -Dspring.config.location=${params.spring_config} \\
        -jar ${params.exomiser_jar} \\
        batch ${batch_file}
    """
}

process POST_PROCESS {
    container params.pheval_exomiser_image

    input:
    val ready

    script:
    def gene_flag    = params.gene_analysis    ? "--gene-analysis"    : "--no-gene-analysis"
    def variant_flag = params.variant_analysis ? "--variant-analysis" : "--no-variant-analysis"
    def disease_flag = params.disease_analysis ? "--disease-analysis" : "--no-disease-analysis"
    """
    pheval-exomiser post-process-exomiser-results \\
        --output-dir ${params.pheval_output_dir} \\
        --results-dir ${params.results_dir} \\
        --phenopacket-dir ${params.phenopacket_dir} \\
        --score-name ${params.score_name} \\
        --sort-order ${params.sort_order} \\
        --version ${params.exomiser_version} \\
        ${gene_flag} \\
        ${variant_flag} \\
        ${disease_flag}
    """
}

workflow {
    PREPARE_BATCHES()
        .flatten()
        .set { batch_files }

    RUN_EXOMISER(batch_files)
        .collect()
        .set { all_done }

    POST_PROCESS(all_done)
}

workflow.onComplete {
    [params.results_dir, params.pheval_output_dir].each { dir ->
        if (dir && new File(dir).exists()) {
            ["chmod", "-R", params.chmod, dir].execute().waitFor()
            log.info "Permissions updated (${params.chmod}): ${dir}"
        }
    }
}
