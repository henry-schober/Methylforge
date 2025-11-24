/*
 * Check input samplesheet and get read channels
 */

include { SAMPLESHEET_CHECK } from '../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:

    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { validate_csv_format(it); create_pod5_channel(it) }
        .set{reads}
    
    SAMPLESHEET_CHECK.out
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { validate_csv_format(it); create_fasta_channel(it) }
        .set{reference_fasta}

    SAMPLESHEET_CHECK.out
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { validate_csv_format(it); create_base_model_channel(it) }
        .set{base_model}
    
    SAMPLESHEET_CHECK.out
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { validate_csv_format(it); create_mod_model_channel(it) }
        .set{mod_model}

    emit:
    reads
    reference_fasta
    base_model
    mod_model
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to validate CSV format before processing
def validate_csv_format(LinkedHashMap row) {
    def required_columns = ['sample', 'pod5_file']

    required_columns.each { col ->
        if (!row.containsKey(col) || row[col] == null || row[col].trim() == "") {
            exit 1, "ERROR: Missing required column '${col}' or empty value in the samplesheet for sample '${row.sample}'!"
        }
    }
}

// Function to get list of [ meta, [ pod5 ] ]
def create_pod5_channel(LinkedHashMap row) {

    def dir = file(row.pod5_file)

    // Ensure directory exists
    if (!dir.exists() || !dir.isDirectory()) {
        exit 1, "ERROR: 'pod5_file' must be a directory containing fast5/pod5 files:\n${row.pod5_file}"
    }

    // List files with allowed extensions
    def files = dir.listFiles().findAll { f ->
        f.name.toLowerCase().endsWith(".fast5") || f.name.toLowerCase().endsWith(".pod5")
    }.collect { f ->
        file(f)
    }

    if (files.isEmpty()) {
        exit 1, "ERROR: Directory contains no .fast5 or .pod5 files:\n${row.pod5_file}"
    }

    // Determine extension — all files must match
    def extensions = files.collect { f ->
        f.getName().substring(f.getName().lastIndexOf('.') + 1).toLowerCase()
    }.unique()

    if (extensions.size() != 1) {
        exit 1, "ERROR: All files in directory must share the same extension (.fast5 or .pod5).\nFound: ${extensions}"
    }

    def ext = extensions[0]  // "fast5" or "pod5"

    // Build metadata
    def meta = [:]
    meta.id = row.sample
    meta.extension = ext

    return [ meta, files ]
}

// Function to get list of [ meta, [ fasta ]]
def create_fasta_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample

    def fasta_meta = []

    if (row.containsKey('fasta') && row.fasta instanceof String && !row.fasta.trim().isEmpty()) {
        if (file(row.fasta).exists()) {
            fasta_meta = [ meta, [ file(row.fasta) ] ]
        } else {
            log.error "FASTA file '${row.fasta}' does not exist for sample '${row.sample}'"
            System.exit(1)
        }
    } else {
        log.info "No FASTA file provided for sample '${row.sample}'."
    }

    return fasta_meta
}

// Function to get list of [ meta, [ base_model ]]
def create_base_model_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample
    meta.has_base   = (row.base_model && row.base_model.trim()) // boolean flag

    def base_model_meta = []

    if (row.containsKey('base_model') && row.base_model instanceof String && !row.base_model.trim().isEmpty()) {
        if (file(row.base_model).exists()) {
            base_model_meta = [ meta, [ file(row.base_model) ] ]
        } else {
            log.error "Base Model file '${row.base_model}' does not exist for sample '${row.sample}'"
            System.exit(1)
        }
    } else {
        log.info "No Base Model provided for sample '${row.sample}'."
        base_model_meta = [meta, ["${params.base_model_name}"]]
    }

    return base_model_meta
}

def create_mod_model_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample
    meta.has_mod    = (row.mod_model && row.mod_model.trim()) // boolean flag

    def mod_model_meta = []

    if (row.containsKey('mod_model') && row.mod_model instanceof String && !row.mod_model.trim().isEmpty()) {
        if (file(row.mod_model).exists()) {
            mod_model_meta = [ meta, [ file(row.mod_model) ] ]
        } else {
            log.error "Mod Model file '${row.mod_model}' does not exist for sample '${row.sample}'"
            System.exit(1)
        }
    } else {
        log.info "No Mod Model provided for sample '${row.sample}'."
        mod_model_meta = [meta, ["${params.mod_model_name}"]]
    }

    return mod_model_meta
}
