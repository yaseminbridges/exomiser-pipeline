nextflow.enable.dsl=2

params.batch_dir      = null
params.exomiser_jar   = null
params.spring_config  = null
params.results_dir    = null
params.chmod          = "g+rw"

// Validate required params
if (!params.batch_dir)     error "Please provide --batch_dir"
if (!params.exomiser_jar)  error "Please provide --exomiser_jar"
if (!params.spring_config) error "Please provide --spring_config"
if (!params.results_dir)   error "Please provide --results_dir"

process RUN_EXOMISER {
    tag "$batch_file.name"

    errorStrategy 'retry'
    maxRetries 3

    input:
    path batch_file

    script:
    """
    java \\
        -Xmx7g \\
        -Dspring.config.location=${params.spring_config} \\
        -jar ${params.exomiser_jar} \\
        batch ${batch_file}
    """
}

workflow {
    Channel
        .fromPath("${params.batch_dir}/*.txt", checkIfExists: true)
        .set { batch_files }
workflow.onComplete {
    def dirs = [
        "reports",
        params.results_dir
    ]
    dirs.each { dir ->
        if (dir && new File(dir).exists()) {
            ["chmod", "-R", params.chmod, dir].execute().waitFor()
            log.info "Permissions updated (${params.chmod}): ${dir}"
        }
    }
}

    RUN_EXOMISER(batch_files)
}

