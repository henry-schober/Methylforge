process DORADO_DOWNLOAD {
    tag "$mod_name"
    label 'process_medium'

    container 'nanoporetech/dorado' //this was autocompleted, unsure if accurate

    input:
    val mod_name


    output:
    path "./dorado/models/${mod_name}", emit: model_path
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when


    script:
    """
    mkdir -p ./dorado/models
    
    dorado download \\
        --model $mod_name \\
        --directory ./dorado/models

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*DORADO v//; s/ .*\$//')
    END_VERSIONS
    """
}