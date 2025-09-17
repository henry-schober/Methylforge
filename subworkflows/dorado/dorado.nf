

include { DORADO_DOWNLOAD as BASE_MODEL_DOWNLOAD} from '../../modules/local/dorado/dorado_download.nf'

include { DORADO_DOWNLOAD as MOD_MODEL_DOWNLOAD} from '../../modules/local/dorado/dorado_download.nf'

include { DORADO_BASECALLER } from '../../modules/local/dorado/dorado_basecaller.nf'


workflow DORADO {
    
    take:
  
        reads  // channel: [ val(meta), [ reads ] ] will change, just want a plceholder for now
           
    main:

    ch_versions = Channel.empty()



    // initialize base model for dorado if not given
    if (params.base_model != null) {
        ch_base_model = Channel.fromPath(params.base_model)
    } else {
        base_model = Channel.value("dna_${params.pore_type}_${params.chemistry_type}_${params.translocation_speed}_sup@${params.model_version}")
        BASE_MODEL_DOWNLOAD(base_model)
        ch_versions = ch_versions.mix(BASE_MODEL_DOWNLOAD.out.versions) 
        ch_base_model = BASE_MODEL_DOWNLOAD.out.model_path       
    }

    // initialize modified model for output_bam later on
    ch_mod = Channel.value("dna_${params.pore_type}_${params.chemistry_type}_${params.translocation_speed}_sup@${params.model_version}_${params.modification_name}@${params.modification_version}")

    if (params.mod_model != null) {
        ch_mod_model = Channel.fromPath(params.mod_model)
    } else {
        MOD_MODEL_DOWNLOAD(ch_mod)
        ch_versions = ch_versions.mix(MOD_MODEL_DOWNLOAD.out.versions)
        ch_mod_model = MOD_MODEL_DOWNLOAD.out.model_path        
    }


    // view channels

    ch_base_model.view { v -> "base model is ${v}" }
    ch_mod_model.view { v -> "mod model is ${v}" }
    reads.view { v -> "reads is ${v}" }



    // run dorado basecaller
    DORADO_BASECALLER(params.batchsize, ch_mod_model, ch_base_model, reads)
    ch_versions = ch_versions.mix(DORADO_BASECALLER.out.versions)
    ch_bam = DORADO_BASECALLER.out.output_bam

    emit:
    ch_bam  // channel: [ val(meta), path(bam) ]


    versions = ch_versions



}