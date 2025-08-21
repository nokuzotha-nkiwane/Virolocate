#!/bin/env bash

#load modules
ON="module miniconda && conda activate viral_pipeline"
eval ${ON}

#directories used
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools"
out="${wdir}/diamond/output"
acc_tax_id="${out}/acc_tax_id.tsv"
lineage_out="${out}/lineages.tsv"
mega_conts="${wdir}/megahit/output/default"


#clear lineage output files
> ${lineage_out}

#get raw lineage information
taxonkit lineage -d $'\t' -i 3 ${acc_tax_id} > ${lineage_out}

#contig filtering according to kingdom viruses
#empty files before extraction
> ${out}/contig_matches.tsv

u_match_out="${out}/unique_contig_ids.txt"
> ${u_match_out}

output_fa="${out}/blast_fasta.fa"
> ${output_fa}

#extract contig matches that are part of viruses
while IFS=$'\t' read -r col1 col2 col3 col4 rest; do
    if [[ ${col4} == *Viruses* ]]; then
        echo -e "${col1}\t${col2}\t${col4}\t${rest}" >> ${out}/contig_matches.tsv
    fi
done < ${lineage_out}

#get unique contig matches
cat ${out}/contig_matches.tsv | awk '{print $1}' > ${u_match_out}
sort -u ${u_match_out} -o ${u_match_out}

#find the contig matches in the final.contigs.fa file
fin_fasta=${mega_conts}/*/sample.contigs.fa

while read -r hit; do
    awk -v contig=">${hit} " '
        index($0, contig) == 1 {print; ON=1; next}
        ON && /^>/ {exit}
        ON {print}
    ' ${fin_fasta} >> ${output_fa}

    #progress check
    echo "Sequence for ${hit} found"
done < ${u_match_out}

exit 0