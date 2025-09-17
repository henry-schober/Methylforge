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
        .map { validate_csv_format(it); create_fastq_channel(it) }
        .set{reads}

    SAMPLESHEET_CHECK.out
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { validate_csv_format(it); create_fasta_channel(it) }
        .set{assembly_reads}

    emit:
    reads
    assembly_reads
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to validate CSV format before processing
def validate_csv_format(LinkedHashMap row) {
    def required_columns = ['sample', 'single_end', 'read_type', 'fastq_1']
    if (!row.single_end.toBoolean()) {
        required_columns.add('fastq_2') // Require fastq_2 for paired-end data
    }

    required_columns.each { col ->
        if (!row.containsKey(col) || row[col] == null || row[col].trim() == "") {
            exit 1, "ERROR: Missing required column '${col}' or empty value in the samplesheet for sample '${row.sample}'!"
        }
    }
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample
    meta.single_end = row.single_end.toBoolean()
    meta.read_type  = row.read_type

    def fastq_meta = []

    // Ensure 'fastq_1' is present and is a string
    if (!row.containsKey('fastq_1') || !(row.fastq_1 instanceof String) || row.fastq_1.trim().isEmpty()) {
        exit 1, "ERROR: Missing or invalid 'fastq_1' in the samplesheet for sample '${row.sample}'!"
    }
    if (!meta.single_end && (!row.containsKey('fastq_2') || !(row.fastq_2 instanceof String) || row.fastq_2.trim().isEmpty())) {
        exit 1, "ERROR: Missing or invalid 'fastq_2' in the samplesheet for sample '${row.sample}'!"
    }

    // Ensure files exist
    if (!file(row.fastq_1).exists()) {
        exit 1, "ERROR: Read 1 FastQ file does not exist!\n${row.fastq_1}"
    }
    if (!meta.single_end && !file(row.fastq_2).exists()) {
        exit 1, "ERROR: Read 2 FastQ file does not exist!\n${row.fastq_2}"
    }

    fastq_meta = meta.single_end ? [ meta, [ file(row.fastq_1) ] ] :
                                   [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]

    return fastq_meta
}

// Function to get list of [ meta, [ fasta ]]
def create_fasta_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample
    meta.single_end = row.single_end.toBoolean()
    meta.read_type  = row.read_type

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
