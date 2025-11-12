process DORADO_DOWNLOAD {
    tag "$meta.id"
    label 'process_medium'

    container 'nanoporetech/dorado:sha268dcb4cd02093e75cdc58821f8b93719c4255ed' //this was autocompleted, unsure if accurate

    input:
    tuple val(meta), val(model)


    output:
    tuple val(meta), path ("dna*"), emit: model_path
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when


    script:
    def mod_name = model[0]
    """
    dorado download \\
        --model $mod_name 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*DORADO v//; s/ .*\$//')
    END_VERSIONS
    """
}