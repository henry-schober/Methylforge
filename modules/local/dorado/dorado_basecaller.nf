process DORADO_BASECALLER {
    tag "$meta.id"
    label 'process_high'

    container 'nanoporetech/dorado'
    //this was autocompleted, unsure if accurate

    input:
    val batchsize
    path mod_model_path
    path base_model_path
    tuple val(meta), path(pod5_files)

    output:
    tuple val(meta), path ("*.bam"), emit: output_bam
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    dorado basecaller \\
        --batchsize $batchsize \\
        --modified-bases-models $mod_model_path \\
        $base_model_path \\
        $pod5_files | samtools view -bS - > ${mod_model_path}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*DORADO v//; s/ .*\$//')
    END_VERSIONS
    """
}