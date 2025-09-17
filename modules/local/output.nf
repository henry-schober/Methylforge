process OUTPUT {
    label 'process_low'

    input:
    tuple val(meta), path(ch_quast_tsv), path(ch_busco), path(ch_merqury_qv), path(ch_merqury_comp)

    output:
    tuple val(meta), path("*.assemblyStats.txt")       , emit: assemblyStats
   
    script: 
    def prefix = task.ext.prefix ?: "${meta.id}" 
    def completeness = "${ch_busco}"

    if( completeness.contains('summary.txt') ){
    """
    prefix=\$(awk 'NR==1 {print \$2}' $ch_quast_tsv)
    echo -ne "quast output\n" >> \$prefix.assemblyStats.txt
    less $ch_quast_tsv >> \$prefix.assemblyStats.txt

    echo -ne "\ncompleasm completeness score\n" >> \$prefix.assemblyStats.txt
    cat $ch_busco >> \$prefix.assemblyStats.txt

    echo -ne "\nmerqury quality score\n" >> \$prefix.assemblyStats.txt
    awk '{ print \$4 }' $ch_merqury_qv >> \$prefix.assemblyStats.txt

    echo -ne "\nmerqury completeness score\n" >> \$prefix.assemblyStats.txt
    awk '{ print \$5 }' $ch_merqury_comp >> \$prefix.assemblyStats.txt
    """ 
    } 
        
    else {
    """
    prefix=\$(awk 'NR==1 {print \$2}' $ch_quast_tsv)
    echo -ne "quast output\n" >> \$prefix.assemblyStats.txt
    less $ch_quast_tsv >> \$prefix.assemblyStats.txt

    echo -ne "\nbusco completeness score\n" >> \$prefix.assemblyStats.txt
    grep -A 17 "Results:" $ch_busco >> \$prefix.assemblyStats.txt

    echo -ne "merqury quality score\n" >> \$prefix.assemblyStats.txt
    awk '{ print \$4 }' $ch_merqury_qv >> \$prefix.assemblyStats.txt

    echo -ne "\nmerqury completeness score\n" >> \$prefix.assemblyStats.txt
    awk '{ print \$5 }' $ch_merqury_comp >> \$prefix.assemblyStats.txt
    """
    }
    
}


process OUTPUT_FORMAT {
    label 'process_low'

    input:
    tuple val(meta), path(input_file)

    output:
    path("*qc.tsv")       , emit: tsv
   
    script: 
    def prefix = task.ext.prefix ?: "${meta.id}"
    if(params.assembly_modules.contains("busco")) {
    """
# Extract the necessary values from the input file
assembly=\$(grep -m 1 "Assembly" "$input_file" | awk '{print \$2}')
contigs=\$(grep -m 1 "# contigs" "$input_file" | awk '{print \$6}')
largest_contig=\$(grep -m 1 "Largest contig" "$input_file" | awk '{print \$3}')
total_length=\$(grep -m 1 "^Total length" "$input_file" | awk '{print \$6}')
gc_percent=\$(grep -m 1 "GC (%)" "$input_file" | awk '{print \$3}')
n50=\$(grep -m 1 "^N50" "$input_file" | awk '{print \$2}')
n90=\$(grep -m 1 "^N90" "$input_file" | awk '{print \$2}')
aun=\$(grep -m 1 "auN" "$input_file" | awk '{print \$2}')
l50=\$(grep -m 1 "L50" "$input_file" | awk '{print \$2}')
l90=\$(grep -m 1 "L90" "$input_file" | awk '{print \$2}')
ns_per_100kbp=\$(grep -m 1 "# N's per 100 kbp" "$input_file" | awk '{print \$6}')

busco_stats=\$(grep "C:" "$input_file" | awk '{print \$1}')
complete_buscos=\$(grep "Complete BUSCOs" "$input_file" | awk '{print \$1}')
single_copy_buscos=\$(grep "single-copy BUSCOs" "$input_file" | awk '{print \$1}')
duplicated_buscos=\$(grep "duplicated BUSCOs" "$input_file" | awk '{print \$1}')
fragmented_buscos=\$(grep "Fragmented BUSCOs" "$input_file" | awk '{print \$1}')
missing_buscos=\$(grep "Missing BUSCOs" "$input_file" | awk '{print \$1}')
total_buscos=\$(grep "Total BUSCO groups searched" "$input_file" | awk '{print \$1}')

merqury_score=\$(sed -n '46p' "$input_file" | awk '{print \$1}')
merqury_comp=\$(sed -n '49p' "$input_file" | awk '{print \$1}')


# Output the formatted results
echo -e "Assembly\t\$assembly\nNumber of contigs\t\$contigs\nLargest contig\t\$largest_contig\nTotal length\t\$total_length\nGC (%)\t\$gc_percent\nN50\t\$n50\nN90\t\$n90\nauN\t\$aun\nL50\t\$l50\nL90\t\$l90\n# N's per 100 kbp\t\$ns_per_100kbp\n\nBUSCO\t\$busco_stats\nComplete BUSCOs (C)\t\$complete_buscos\nComplete and single-copy BUSCOs (S)\t\$single_copy_buscos\nComplete and duplicated BUSCOs (D)\t\$duplicated_buscos\nFragmented BUSCOs (F)\t\$fragmented_buscos\nMissing BUSCOs (M)\t\$missing_buscos\nTotal BUSCO groups searched\t\$total_buscos\n\nMerqury quality value\t\$merqury_score\nMerqury completeness value\t\$merqury_comp" >> ${prefix}_qc.tsv

    """ } else if (params.assembly_modules.contains("compleasm") || params.assembly_modules.contains("all")) {
    """
# Extract the necessary values from the input file
assembly=\$(grep -m 1 "Assembly" "$input_file" | awk '{print \$2}')
contigs=\$(grep -m 1 "# contigs" "$input_file" | awk '{print \$6}')
largest_contig=\$(grep -m 1 "Largest contig" "$input_file" | awk '{print \$3}')
total_length=\$(grep -m 1 "^Total length" "$input_file" | awk '{print \$6}')
gc_percent=\$(grep -m 1 "GC (%)" "$input_file" | awk '{print \$3}')
n50=\$(grep -m 1 "^N50" "$input_file" | awk '{print \$2}')
n90=\$(grep -m 1 "^N90" "$input_file" | awk '{print \$2}')
aun=\$(grep -m 1 "auN" "$input_file" | awk '{print \$2}')
l50=\$(grep -m 1 "L50" "$input_file" | awk '{print \$2}')
l90=\$(grep -m 1 "L90" "$input_file" | awk '{print \$2}')
ns_per_100kbp=\$(grep -m 1 "# N's per 100 kbp" "$input_file" | awk '{print \$6}')

# Extract the BUSCO values from the input file
S=\$(grep "^S:" "$input_file" | awk '{print \$1}' | sed 's/S://; s/,//')
D=\$(grep "^D:" "$input_file" | awk '{print \$1}' | sed 's/D://; s/,//')
F=\$(grep "^F:" "$input_file" | awk '{print \$1}' | sed 's/F://; s/,//')
I=\$(grep "^I:" "$input_file" | awk '{print \$1}' | sed 's/I://; s/,//')
M=\$(grep "^M:" "$input_file" | awk '{print \$1}' | sed 's/M://; s/,//')
N=\$(grep "^N:" "$input_file" | awk '{print \$1}' | sed 's/N://; s/,//')

# Extract the counts associated with each category
S_count=\$(grep "^S:" "$input_file" | awk '{print \$2}')
D_count=\$(grep "^D:" "$input_file" | awk '{print \$2}')
F_count=\$(grep "^F:" "$input_file" | awk '{print \$2}')
I_count=\$(grep "^I:" "$input_file" | awk '{print \$2}')
M_count=\$(grep "^M:" "$input_file" | awk '{print \$2}')
N_count=\$(grep "^N:" "$input_file" | awk '{print \$2}')

merqury_score=\$(sed -n '36p' "$input_file" | awk '{print \$1}')
merqury_comp=\$(sed -n '39p' "$input_file" | awk '{print \$1}')

# Output the formatted results
echo -e "Assembly\t\$assembly\nNumber of contigs\t\$contigs\nLargest contig\t\$largest_contig\nTotal length\t\$total_length\nGC (%)\t\$gc_percent\nN50\t\$n50\nN90\t\$n90\nauN\t\$aun\nL50\t\$l50\nL90\t\$l90\n# N's per 100 kbp\t\$ns_per_100kbp\n\nCompleasm\tS:\$S,D:\$D,F:\$F,M:\$M,n:\$N\nComplete and single-copy BUSCOs (S):\t\$S_count (\$S)\nComplete and duplicated BUSCOs (D):\t\$D_count (\$D)\nFragmented BUSCOs (F):\t\$F_count (\$F)\nMissing BUSCOs (M):\t\$M_count (\$M)\nTotal BUSCO groups searched (N):\t\$N\n\nMerqury quality value\t\$merqury_score\nMerqury completeness value\t\$merqury_comp" >> ${prefix}_qc.tsv

    """
    }
}


process OUTPUT_COMBINE {
    label 'process_low'

    input:
    path(input_files)

    output:
    path("all_assemblyStats.tsv")       , emit: assemblyStats
   
    script: 
    def prefix
    """
    file_array_1=(\$(ls ${input_files}))

    ls ${input_files} > file_names.txt

    # List the files and their line lengths

    awk '{ print length(), \$0 | "sort -n" }' file_names.txt > sorted_files_int.txt
    awk '{print \$2}' sorted_files_int.txt  > sorted_files.txt

    # Extract only the filenames from the sorted file
    file_array_2=(\$(cat sorted_files.txt))

    output_file="\${file_array_2[0]}"

    # Loop through the rest of the files and join them one by one
    for file in "\${file_array_2[@]:1}"; do
        tmp_file=\$(mktemp)
        join -t \$'\\t' "\$output_file" "\$file" > "\$tmp_file"
        mv "\$tmp_file" "\$output_file"
    done

    # Optionally save the final output to a file
    mv "\$output_file" all_assemblyStats.tsv

    """
}



