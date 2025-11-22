



include { DORADO_DOWNLOAD as DORADO_DOWNLOAD_MOD} from '../../modules/local/dorado/dorado_download.nf'

include { DORADO_DOWNLOAD as DORADO_DOWNLOAD_BASE} from '../../modules/local/dorado/dorado_download.nf'

include { DORADO_BASECALLER } from '../../modules/local/dorado/dorado_basecaller.nf'

include { SAMTOOLS_SORT } from '../../modules/nf-core/samtools/sort.nf'

include { SAMTOOLS_INDEX } from '../../modules/nf-core/samtools/index/main.nf'


workflow DORADO {
    
    take:
  
        ch_reads  // channel: [ val(meta), [ pod5 ] ] will change, just want a plceholder for now
        ch_reference_fasta  // channel: [ val(meta), path(fasta) ]
        ch_base_model  // channel: [ val(meta), path(model) ]
        ch_mod_model  // channel: [ val(meta), path(model) ]

           
    main:

    ch_versions = Channel.empty()

    //ch_mod_dir = Channel.value("${projectDir}/dorado/models")


    ch_base_final = Channel.empty()
    ch_mod_final = Channel.empty()

    ch_base = ch_base_model
        .branch { 
            meta, model ->
                has_model: meta.has_base
                    return [meta, model]
                no_model: !meta.has_base
                    return [meta, model]
        }

    ch_base.no_model.view { v -> "base model without model channel is ${v}" }
    ch_base.has_model.view { v -> "base model with model channel is ${v}" }


    DORADO_DOWNLOAD_BASE(ch_base.no_model).model_path.mix(ch_base.has_model).set { ch_base_final }

    ch_base_final.view { v -> "final base model is ${v}" }

    ch_mod = ch_mod_model
        .branch { 
            meta, model ->
                has_model: meta.has_mod
                    return [meta, model]
                no_model: !meta.has_mod
                    return [meta, model]
        }

    ch_mod.no_model.view { v -> "mod model without model channel is ${v}" }
    ch_mod.has_model.view { v -> "mod model with model channel is ${v}" }


    DORADO_DOWNLOAD_MOD(ch_mod.no_model).model_path.mix(ch_mod.has_model).set { ch_mod_final }

    ch_mod_final.view { v -> "final mod model is ${v}" }

    ch_indexed_bam = Channel.empty()

    if (params.basecalling_only) {
        // run basecaller without the reference
        DORADO_BASECALLER(ch_mod_final, ch_base_final, ch_reads, [[], []])
        ch_versions = ch_versions.mix(DORADO_BASECALLER.out.versions)
        ch_bam = DORADO_BASECALLER.out.output_bam
    } else {
        // run dorado basecaller
        DORADO_BASECALLER(ch_mod_final, ch_base_final, ch_reads, ch_reference_fasta)
        ch_versions = ch_versions.mix(DORADO_BASECALLER.out.versions)
        ch_bam = DORADO_BASECALLER.out.output_bam 

        ch_bam.view { v -> "bam channel is ${v}" }
        
        SAMTOOLS_SORT(ch_bam)

        SAMTOOLS_INDEX(SAMTOOLS_SORT.out.bam)
        ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)
        ch_bai = SAMTOOLS_INDEX.out.bai

        SAMTOOLS_SORT.out.bam.join(ch_bai).set { ch_indexed_bam }

        
        ch_indexed_bam.view { v -> "indexed channel is ${v}" }
    }

    emit:
    ch_bam  // channel: [ val(meta), path(bam) ]
    ch_indexed_bam  // channel: [ val(meta), path(bam), path(bai) ]
    ch_reference_fasta  // channel: [ val(meta), path(fasta) ]


    versions = ch_versions



}