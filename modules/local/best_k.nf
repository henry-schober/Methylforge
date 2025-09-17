process BEST_K {
    tag "$manual_genome_size"
    label 'process_low'

    conda "bioconda::merqury=1.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/merqury:1.3--hdfd78af_1':
        'biocontainers/merqury:1.3--hdfd78af_1' }"

    input:
    val manual_genome_size
    val tolerable_collision_rate


    output:
    path ("best_kmer_num.txt")   , emit: kmer
    path "versions.yml"                            , emit: versions

    script:
    // prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = 1.3
    def genome_size

    """

    # Nextflow changes the container --entrypoint to /bin/bash (container default entrypoint: /usr/local/env-execute)
    # Check for container variable initialisation script and source it.
    if [ -f "/usr/local/env-activate.sh" ]; then
        set +u  # Otherwise, errors out because of various unbound variables
        . "/usr/local/env-activate.sh"
        set -u
    fi
    # limit meryl to use the assigned number of cores.
    export OMP_NUM_THREADS=$task.cpus

    genome_size=\$(echo \$(${manual_genome_size}))

    /usr/local/share/merqury/best_k.sh $manual_genome_size $tolerable_collision_rate > best_kmer_num.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        best_k: $VERSION
    END_VERSIONS
    """
}