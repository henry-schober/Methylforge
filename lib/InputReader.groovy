import nextflow.Nextflow

import java.nio.file.Path

class InputReader {

    ArrayList<Path> channel

    InputReader ( String inputPath ) {
        
        // read samplesheet into groovy
        List rows = readSampleSheet(inputPath)
        Nextflow.log.info "Samplesheet contains ${rows.size()} entries. Contents: ${rows}"

        // reformat it into more useful channels
        this.channel = samplesheetToChannel(rows)

    }


    private List readSampleSheet( String inputPath ) {
        // skip header, read rows into map
        File inputFile = new File(inputPath)
        def rows = []
        inputFile.withReader { reader ->
            def header = reader.readLine().split(",") // column names
            //TODO: Perform some kind of validation on header here
            reader.eachLine { line ->
                if (!line?.trim()) return // skip blanks
                def values = line.split(",", -1) // keep empty fields
                //TODO: perform some kind of validation on values here
                def row = [ : ]
                header.eachWithIndex { col, i ->
                    row[col] = (i < values.size()) ? values[i] : ""
                }
                rows << row
            }
        }
        return rows
    }

    private ArrayList<Path> samplesheetToChannel( List rows ) {
        def ch = []
        rows.each { row ->

            ch << [ [id: row.SAMPLE_NAME], row.POD5_FILE, row.BASE_MODEL, row.MOD_MODEL ]
        }
        return ch
    }
}
