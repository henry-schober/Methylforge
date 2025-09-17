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
        .map { validate_csv_format(it); create_base_model_channel(it) }
        .set{base_model}
    
    SAMPLESHEET_CHECK.out
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { validate_csv_format(it); create_mod_model_channel(it) }
        .set{mod_model}

    emit:
    reads
    base_model
    mod_model
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to validate CSV format before processing
def validate_csv_format(LinkedHashMap row) {
    def required_columns = ['sample', 'pod5', 'base_model', 'mod_model']

    required_columns.each { col ->
        if (!row.containsKey(col) || row[col] == null || row[col].trim() == "") {
            exit 1, "ERROR: Missing required column '${col}' or empty value in the samplesheet for sample '${row.sample}'!"
        }
    }
}

// Function to get list of [ meta, [ pod5 ] ]
def create_pod5_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample

    def pod5_meta = []

    // Ensure 'pod5' is present and is a string
    if (!row.containsKey('pod5') || !(row.pod5 instanceof String) || row.pod5.trim().isEmpty()) {
        exit 1, "ERROR: Missing or invalid 'pod5' in the samplesheet for sample '${row.sample}'!"
    }

    // Ensure files exist
    if (!file(row.pod5).exists()) {
        exit 1, "ERROR: Read 1 pod5 file does not exist!\n${row.pod5}"
    }


    pod5_meta = [ meta, [ file(row.pod5) ] ]

    return pod5_meta
}

// Function to get list of [ meta, [ base_model ]]
def create_base_model_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample

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
    }

    return base_model_meta
}

def create_mod_model_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample

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
    }

    return mod_model_meta
}
