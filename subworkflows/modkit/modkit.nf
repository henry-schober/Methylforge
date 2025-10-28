include { MODKIT_PILEUP} from '../../modules/nf-core/modkit/pileup/main.nf'


workflow MODKIT {
    
    take:
  
        ch_indexed_bam // channel: [ [val(meta)], bam file, bai file ] will change, just want a placeholder for now
        ch_fasta      // channel: [ val(meta), [ fasta file ] ] will change, just want a placeholder for now
           
    main:

    ch_versions = Channel.empty()




    MODKIT_PILEUP(ch_indexed_bam, ch_fasta, [[],[]])
    ch_versions = ch_versions.mix(MODKIT_PILEUP.out.versions)
    ch_bed = MODKIT_PILEUP.out.bed

    

    emit:
    ch_bed  // channel: [ val(meta), path(bam) ]


    versions = ch_versions



}