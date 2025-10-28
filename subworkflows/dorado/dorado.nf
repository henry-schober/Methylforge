



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

    if (params.basecalling_model.contains("download")) {
        ch_base_name = Channel.value("dna_${params.pore_type}_${params.chemistry_type}_${params.translocation_speed}_${params.model_type}@${params.model_version}")
        ch_mod_name = Channel.value("dna_${params.pore_type}_${params.chemistry_type}_${params.translocation_speed}_${params.model_type}@${params.model_version}_${params.modification_name}@${params.modification_version}")
        DORADO_DOWNLOAD_BASE(ch_base_name)
        ch_versions = ch_versions.mix(DORADO_DOWNLOAD_BASE.out.versions)
        DORADO_DOWNLOAD_BASE.out.model_path
            .set { ch_base_model }

        DORADO_DOWNLOAD_MOD(ch_mod_name)
        ch_versions = ch_versions.mix(DORADO_DOWNLOAD_MOD.out.versions)
        DORADO_DOWNLOAD_MOD.out.model_path
            .set { ch_mod_model } 
    } else if (params.basecalling_model.contains("provided")) {
        reads.map { sampleName, pod5File, fastaFile, baseModel, modModel ->
            baseModel    // pass valid path
        }
            .set { ch_base_model }  // channel with valid model paths only
        
        reads.map { sampleName, pod5File, fastaFile, baseModel, modModel ->
            modModel    // pass valid path
        }
            .set { ch_mod_model }
    } else {
        exit 1, "ERROR: basecalling_model parameter must be either 'download' or 'provided'"
    }

    ch_base_model.view { v -> "base model is ${v}" }
    ch_mod_model.view { v -> "mod model is ${v}" }


    ch_pod5 = reads
        .map { tuple(it[0], it[1]) } 

    ch_pod5.view { v -> "ch_pod5 is ${v}" }
    
    ch_fasta = reads
        .map { tuple(it[0], it[2]) } 

    ch_fasta.view { v -> "ch_fasta is ${v}" }

  

    // run dorado basecaller
    DORADO_BASECALLER(ch_mod_model, ch_base_model, ch_pod5, ch_fasta)
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
    ch_fasta  // channel: [ val(meta), path(fasta) ]


    versions = ch_versions



}