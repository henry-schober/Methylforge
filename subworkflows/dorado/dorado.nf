



include { DORADO_DOWNLOAD as DORADO_DOWNLOAD_MOD} from '../../modules/local/dorado/dorado_download.nf'

include { DORADO_DOWNLOAD as DORADO_DOWNLOAD_BASE} from '../../modules/local/dorado/dorado_download.nf'

include { DORADO_BASECALLER } from '../../modules/local/dorado/dorado_basecaller.nf'

include { SAMTOOLS_SORT } from '../../modules/nf-core/samtools/sort.nf'

include { SAMTOOLS_INDEX } from '../../modules/nf-core/samtools/index/main.nf'


workflow DORADO {
    
    take:
  
        reads  // channel: [ val(meta), [ reads ] ] will change, just want a plceholder for now
           
    main:

    ch_versions = Channel.empty()

    //ch_mod_dir = Channel.value("${projectDir}/dorado/models")



    reads
        .filter { it[2] != null }           // modModel exists
        .map { sampleName, pod5File, baseModel, modModel ->
            tuple(sampleName, baseModel)    // pass valid path
        }
        .set { ch_base_model }  // channel with valid model paths only
    

    ch_base_name = Channel.value("dna_${params.pore_type}_${params.chemistry_type}_${params.translocation_speed}_${params.model_type}@${params.model_version}")
    reads
        .filter { it[2] == null }          // modModel missing
        .map { sampleName, pod5File, baseModel, modModel ->
            tuple(sampleName)              // no path
        }
        .set {no_base_model}  // channel with missing model paths only

    no_base_model.concat(ch_base_name)
        .set { ch_base_model_missing }  // channel with missing model paths only

    DORADO_DOWNLOAD_BASE(ch_base_model_missing)
    ch_versions = ch_versions.mix(DORADO_DOWNLOAD_BASE.out.versions)
    DORADO_DOWNLOAD_BASE.out.model_path
        .set { ch_base_model }

    ch_base_model_missing.view { v -> "ch_base_model_missing is ${v}" }
    ch_base_model.view { v -> "ch_base_model is ${v}" }



    
    reads
        .filter { it[3] != null }           // modModel exists
        .map { sampleName, pod5File, baseModel, modModel ->
            tuple(sampleName, modModel)    // pass valid path
        }
        .set { ch_mod_model }  // channel with valid model paths only
    

    ch_mod_name = Channel.value("dna_${params.pore_type}_${params.chemistry_type}_${params.translocation_speed}_${params.model_type}@${params.model_version}_${params.modification_name}@${params.modification_version}")
    reads
        .filter { it[3] == null }          // modModel missing
        .map { sampleName, pod5File, baseModel, modModel ->
            tuple(sampleName)              // no path
        }
        .set {no_mod_model}  // channel with missing model paths only

    no_mod_model.concat(ch_mod_name)
        .set { ch_mod_model_missing }  // channel with missing model paths only

    DORADO_DOWNLOAD_MOD(ch_mod_model_missing)
    ch_versions = ch_versions.mix(DORADO_DOWNLOAD_MOD.out.versions)
    DORADO_DOWNLOAD_MOD.out.model_path
        .set { ch_mod_model }  



    ch_mod_model_missing.view { v -> "ch_mod_model_missing is ${v}" }
    ch_mod_model.view { v -> "ch_mod_model is ${v}" }


    ch_pod5 = reads
        .map { tuple(it[0], it[1]) } 

    ch_pod5.view { v -> "ch_pod5 is ${v}" }
    




/*
    // initialize modified model for output_bam later on
    ch_mod = Channel.value("dna_${params.pore_type}_${params.chemistry_type}_${params.translocation_speed}_sup@${params.model_version}_${params.modification_name}@${params.modification_version}")

    if (params.mod_model != null) {
        ch_mod_model = Channel.fromPath(params.mod_model)
    } else {
        MOD_MODEL_DOWNLOAD(ch_mod)
        ch_versions = ch_versions.mix(MOD_MODEL_DOWNLOAD.out.versions)
        ch_mod_model = MOD_MODEL_DOWNLOAD.out.model_path        
    }
*/

    // view channels


    ch_mod_model.view { v -> "mod model is ${v}" }




    // run dorado basecaller
    DORADO_BASECALLER(params.batchsize, ch_mod_model, ch_base_model, ch_pod5)
    ch_versions = ch_versions.mix(DORADO_BASECALLER.out.versions)
    ch_bam = DORADO_BASECALLER.out.output_bam 


    SAMTOOLS_SORT(ch_bam)

    SAMTOOLS_INDEX(SAMTOOLS_SORT.out.bam)
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)
    ch_bai = SAMTOOLS_INDEX.out.bai

    ch_indexed_bam = SAMTOOLS_SORT.out.bam.join(ch_bai)

    
    ch_indexed_bam.view { v -> "indexed channel is ${v}" }

    emit:
    ch_bam  // channel: [ val(meta), path(bam) ]
    ch_indexed_bam  // channel: [ val(meta), path(bam), path(bai) ]


    versions = ch_versions



}