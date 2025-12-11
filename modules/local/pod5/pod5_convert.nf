process POD5_CONVERT {
    tag "$meta.id"
    label 'process_medium'

    container 'quay.io/biocontainers/pod5:0.3.33--pyhdfd78af_0' 

    input:
    tuple val(meta), path(fast5_file)


    output:
    tuple val(meta), path ("*.pod5"), emit: converted_pod5
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    // write the prefix to the meta
    script:
    """
    pod5 convert fast5 $fast5_file \\
        --output "${meta.prefix}.pod5" \\
        --force


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*DORADO v//; s/ .*\$//')
    END_VERSIONS
    """
}

process COLLECT_POD5 {
    tag "$meta.id"
    label 'process_medium'

    container 'quay.io/biocontainers/pod5:0.3.33--pyhdfd78af_0' 

    input:
    tuple val(meta), path(pod5_list)

    output:
    tuple val(meta), path("collected_pod5"), emit: collected_pod5

    script:
    """
    mkdir -p collected_pod5
    ln -s ${pod5_list.join(' ')} collected_pod5/
    """
}