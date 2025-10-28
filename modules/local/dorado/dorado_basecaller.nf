process DORADO_BASECALLER {
    tag "$meta.id"
    label 'process_high'

    container 'nanoporetech/dorado'
    //this was autocompleted, unsure if accurate

    input:
    path mod_model_path
    path base_model_path
    tuple val(meta), path(pod5_files)
    tuple val(meta2), path(fasta)

    output:
    tuple val(meta), path ("*.bam"), emit: output_bam
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args ?: ''
    def prefix      = task.ext.prefix ?: "${meta.id}" // another fix for later
    // def reference   = fasta ? "--reference ${fasta}" : "" //fix this for later
    """
    dorado basecaller \\
        $args \\
        --modified-bases-models $mod_model_path \\
        $base_model_path \\
        --reference $fasta \\
        $pod5_files | samtools view -bS - > ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*DORADO v//; s/ .*\$//')
    END_VERSIONS
    """
}