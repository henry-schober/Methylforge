process BLOBTOOLS_CONFIG {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path('*config.yaml'), emit: config

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def configContent = """
    assembly:
      accession: ${meta.id}
      file: $assembly
      level: scaffold
      prefix: ${meta.id}
    busco:
      download_dir: ${params.busco_lineage}
      lineages:
        - ${params.busco_lineage}
      basal_lineages:
        - ${params.busco_lineage}
        
    """

    // Write the combined configuration to the output file
    """
    echo '$configContent' > ${prefix}_config.yaml
    """
}


process BLOBTOOLS_BLAST {
    tag "$meta.id"
    label 'process_high'

    container 'ncbi/blast'

    input:
    tuple val(meta), path(assembly)

    output:
    path('*.out'), emit: hits

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    blastn -db ${params.blast_db} \\
       -query $assembly \\
       -outfmt "6 qseqid staxids bitscore std" \\
       -max_target_seqs 10 \\
       -max_hsps 1 \\
       -evalue 1e-25 \\
       -num_threads $task.cpus \\
       -out ${prefix}_blast_hits.out

    """
}    


process BLOBTOOLS_RUN {
    tag "$meta.id"
    label 'process_high'

    container 'genomehubs/blobtoolkit:latest'

    input:
    tuple val(meta), path(assembly), path(busco_full_table_tsv), path(bam)
    tuple val(meta), path(config)
    path blast_hits
    val taxon_taxid
    path taxon_taxdump

    output:
    tuple val(meta), path('*/*.json'), emit: json
    tuple val(meta), path('db_*') , emit: db
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def taxid = taxon_taxid ? "--taxid ${taxon_taxid}" : ''
    def taxdump = taxon_taxdump ? "--taxdump ${taxon_taxdump}" : ''
    def blast = blast_hits ? "--hits ${blast_hits}" : ''
    """
    blobtools create \\
        --fasta $assembly \\
        --meta $config \\
        $taxid \\
        $taxdump \\
        db_${assembly}
    
    blobtools add \\
        --busco $busco_full_table_tsv \\
        --cov $bam \\
        $blast \\
        $taxid \\
        $taxdump \\
        db_${assembly}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blobtools: \$(blobtools --version | sed -e "s/blobtoolkit v//g")
    END_VERSIONS
    """
}


process BLOBTOOLS_VIEW {
    tag "$meta.id"
    label 'process_medium'

    container 'genomehubs/blobtk'

    input:
    tuple val(meta), path(db)

    output:
    tuple val(meta), path('*.png') , emit: png

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """        
    blobtk plot -v snail -d $db -o ${db}_snail.png 

    blobtk plot -v cumulative -d $db -o ${db}_cumulative.png

    blobtk plot -v blob -d $db -o ${db}_blob.png 

    """
}