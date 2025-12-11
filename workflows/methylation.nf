/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowMethylation.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.centrifuge_db ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }
*/
// Check mandatory parameters

if (params.input) { ch_input = file(params.input) }

//if (params.summary_txt) {ch_sequencing_summary = file(params.sequencing_summary) } else { ch_sequencing_summary = []}




/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
//ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
//ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
//ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// MODULES

include { POD5_CONVERT } from '../modules/local/pod5/pod5_convert.nf'

include { COLLECT_POD5 } from '../modules/local/pod5/pod5_convert.nf'

// SUBWORKFLOWS
include { INPUT_CHECK } from '../subworkflows/input_check'

include { DORADO } from '../subworkflows/dorado/dorado.nf'

include { MODKIT } from '../subworkflows/modkit/modkit.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow METHLYATION {
    
    ch_versions = Channel.empty()

    INPUT_CHECK(ch_input)

    ch_reference_fasta = Channel.empty()

    //ch_reads = INPUT_CHECK.out.reads
    ch_reference_fasta = INPUT_CHECK.out.reference_fasta
    ch_base_model = INPUT_CHECK.out.base_model
    ch_mod_model = INPUT_CHECK.out.mod_model

    //ch_reads.view { v -> "ch_reads is ${v}" }
    // ch_reference_fasta.view { v -> "ch_reference_fasta is ${v}" }

    ch_pod5 = Channel.empty()

    // INPUT_CHECK.out.reads.view { v -> "INPUT_CHECK.out.reads is ${v}" }


    ch_reads = INPUT_CHECK.out.reads
        .branch { 
            meta, files ->
                is_fast5: meta.extension == "fast5"
                    return [meta, files]
                is_pod5: meta.extension == "pod5"
                    return [meta, files]
            }
    // ch_reads.is_fast5.view { v -> "fast5 reads channel is ${v}" }
    // ch_reads.is_pod5.view { v -> "pod5 reads channel is ${v}" }
    

    INPUT_CHECK.out.reads
        .map { meta, files -> [[meta], files].combinations() }
        .flatten()
        .collate( 2 )
        .set{ ch_flat_reads }

    // ch_flat_reads.view { v -> "pbconvert input channel is ${v}" }

    ch_test = Channel.empty()
    ch_test = ch_flat_reads.branch {
            meta, files ->
                is_fast5: meta.extension == "fast5"
                    return [meta + [prefix:files.baseName], files]
                is_pod5: meta.extension == "pod5"
                    return [meta + [prefix:files.baseName], files]
            }

    // ch_test.is_fast5.view { v -> "fast5 test channel is ${v}" }
    // ch_test.is_pod5.view { v -> "pod5 test channel is ${v}" }




    POD5_CONVERT(ch_test.is_fast5).converted_pod5.mix(ch_test.is_pod5).set { ch_pod5 }

    ch_pod5
        .collect(flat: false)
        .map { list_of_pairs ->
            def first_meta = list_of_pairs[0][0]
            def cleaned_prefix = first_meta.prefix.replaceAll(/_\d+$/, '')
            def meta_list = [
                id: first_meta.id,
                extension: first_meta.extension,
                prefix: cleaned_prefix
            ]
            def file_list = list_of_pairs.collect { it[1] }
            return [ meta_list, file_list ]
        }
        .set { ch_final_pod5 }

    ch_final_pod5.view { v -> "converted/final pod5 channel is ${v}" }

    //COLLECT_POD5( ch_final_pod5 ).collected_pod5.set { ch_pod5_dir }

    //ch_pod5_dir.view { v -> "final collected pod5 channel is ${v}" }


    DORADO (
        ch_final_pod5, ch_reference_fasta, ch_base_model, ch_mod_model
    )
    ch_versions = ch_versions.mix(DORADO.out.versions)

    DORADO.out.ch_reference_fasta.view { v -> "DORADO.out.ch_reference_fasta is ${v}" }
    if (!params.basecalling_only) {
        MODKIT(DORADO.out.ch_indexed_bam, DORADO.out.ch_reference_fasta)
        ch_versions = ch_versions.mix(MODKIT.out.versions)
    } 


}
    //
    // MODULE: MultiQC
    //
   //workflow_summary    = WorkflowGenomeassembly.paramsSummaryMultiqc(workflow, summary_params)
   //ch_workflow_summary = Channel.value(workflow_summary)

    //methods_description    = WorkflowGenomeassembly.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    //ch_methods_description = Channel.value(methods_description)

    //ch_multiqc_files = Channel.empty()
    //ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    //ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    //ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    //ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    //MULTIQC (
    //    ch_multiqc_files.collect(),
    //    ch_multiqc_config.toList(),
    //    ch_multiqc_custom_config.toList(),
    //    ch_multiqc_logo.toList()
   //)
    //multiqc_report = MULTIQC.out.report.toList()


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
