



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


/*
    ch_with_model.view { v -> "base model with model channel is ${v}" }
    ch_without_model.view { v -> "base model without model channel is ${v}" }

    ch_base_model
        .filter { meta, model_list -> meta.has_model }
        .set { ch_base }

    ch_base_model
        .filter { meta, model_list -> !meta.has_model }
        .set { ch_base_name }

    ch_base_name.view {v -> "base model name channel is ${v}"}
    DORADO_DOWNLOAD_BASE(ch_base_name)
    ch_versions = ch_versions.mix(DORADO_DOWNLOAD_BASE.out.versions)
    DORADO_DOWNLOAD_BASE.out.model_path
        .set { ch_base_downloaded } 
    
    ch_base_downloaded.v {v -> "downloaded the model here ${v}"}

    ch_base.view { v -> "base model is ${v}" }   
*/



/*

    if (params.basecalling_model.contains("download")) {
        ch_base_name = Channel.value("dna_${params.pore_type}_${params.chemistry_type}_${params.translocation_speed}_${params.model_type}@${params.model_version}")
        ch_mod_name = Channel.value("dna_${params.pore_type}_${params.chemistry_type}_${params.translocation_speed}_${params.model_type}@${params.model_version}_${params.modification_name}@${params.modification_version}")
        DORADO_DOWNLOAD_BASE(ch_base_name)
        ch_versions = ch_versions.mix(DORADO_DOWNLOAD_BASE.out.versions)
        DORADO_DOWNLOAD_BASE.out.model_path
            .set { ch_base }

        DORADO_DOWNLOAD_MOD(ch_mod_name)
        ch_versions = ch_versions.mix(DORADO_DOWNLOAD_MOD.out.versions)
        DORADO_DOWNLOAD_MOD.out.model_path
            .set { ch_mod } 
    } else if (params.basecalling_model.contains("provided")) {
        ch_base_model.set { ch_base }
        ch_mod_model.set { ch_mod }
    } else {
        exit 1, "ERROR: basecalling_model parameter must be either 'download' or 'provided'"
    }

    ch_base.view { v -> "base model is ${v}" }
    ch_mod.view { v -> "mod model is ${v}" }
    */



    // run dorado basecaller
    DORADO_BASECALLER(ch_mod_final, ch_base_final, ch_reads, ch_reference_fasta)
    ch_versions = ch_versions.mix(DORADO_BASECALLER.out.versions)
    ch_bam = DORADO_BASECALLER.out.output_bam 

    ch_bam.view { v -> "bam channel is ${v}" }
    
    SAMTOOLS_SORT(ch_bam)

    SAMTOOLS_INDEX(SAMTOOLS_SORT.out.bam)
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)
    ch_bai = SAMTOOLS_INDEX.out.bai

    ch_indexed_bam = SAMTOOLS_SORT.out.bam.join(ch_bai)

    
    ch_indexed_bam.view { v -> "indexed channel is ${v}" }


    emit:
    ch_bam  // channel: [ val(meta), path(bam) ]
    ch_indexed_bam  // channel: [ val(meta), path(bam), path(bai) ]
    ch_reference_fasta  // channel: [ val(meta), path(fasta) ]


    versions = ch_versions



}