#!/bin/env bash

#load modules
module ncbi
ON="module miniconda && conda activate viral_pipeline"

#directories
wdir="/analyses/users/nokuzothan/disc_pipe"
db_fa="${wdir}/ncbidb/nt/nt"
diamond_out="${wdir}/init_tools/diamond/output"
input_fa="${diamond_out}/blast_fasta.fa"
blastn_out="${wdir}/init_tools/blastn/output"
output="${blastn_out}/blastn_output_3.tsv"
blastn_tax_tmp_1="${blastn_out}/contig_acc.txt"
blastn_tax_tmp_2="${blastn_out}/contig_acc_tax.txt"
blastn_tax="${blastn_out}/blastn_taxonomy.tsv"
threads=$((`/bin/nproc` -2))

# #make blastn_results subdirectory in blastn output folder
# if [[ -e ${blastn_out} ]]; then
#     rm -rf ${blastn_out}
# fi
# mkdir -p -m a=rwx ${blastn_out}

#blastn run
if [[ -s ${input_fa} ]]; then
    echo "Running blastn"
    blastn -query ${input_fa} \
        -db ${db_fa} \
        -out ${output}\
        -strand both \
        -num_threads ${threads} \
        -evalue 1E-5 \
        -outfmt "6 qseqid qlen sseqid stitle pident length qstart qend evalue bitscore" \
        -perc_identity 80 \
        -max_target_seqs 5

else
    echo "Query fasta file of samples does not exist or is empty, skipping blastn."
fi


#extract contigs ids and accession numbers from blastn_output.tsv

#get taxonomic ids
function get_tax_id {
    contig=$1
    acc_id=$2
    output=$3

    #get uid first which links the accesion id to the taxonid (filter the json output using jq to get uid)
    url1="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nuccore&term=${acc_id}&retmode=json"
    uid=$(curl -N -# "${url1}" | tr -d '\r\n' | jq -r '.esearchresult.idlist[0]')


    #get taxon id using uid
    if [[ -n ${uid} ]]; then

        #link to get taxon id using uid
        url2="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=nuccore&id=${uid}&retmode=json" 
        tax_id=$(curl -N -# "${url2}" | tr -d '\r\n' | jq -r ".result[\"${uid}\"].taxid")


        #print output
        echo -e "${contig}\t${acc_id}\t${tax_id}" >>${output}

    #if no taxon id found
    else
        echo -e "${contig}\t${acc_id}\tNOT_FOUND" >> ${output}
    fi

} 

#clear files
echo "Clearing previous run's files"
> ${blastn_tax_tmp_1}
> ${blastn_tax_tmp_2}
> ${blastn_tax}

#make file of sample ids and accession ids from blastn output

#progress check
echo "Making contig_acc.txt file"

while IFS=$'\t' read -r col1 col2 col3 rest; do
    acc=$(echo -e ${col3} | cut -d "|" -f4)
    echo -e "${col1}\t${acc}" >> ${blastn_tax_tmp_1}
done < ${output}

#deduplicate above file so no unneccary taxonomy id calls are made
sort -u ${blastn_tax_tmp_1} -o ${blastn_tax_tmp_1}

#progress check
echo " Unique contig_acc_tax.txt file made"

#function call to write out taxon ids to output file

#progress check
echo "Acquiring taxonomic ids"
while IFS=$'\t' read -r col1 col2; do
    get_tax_id ${col1} ${col2} ${blastn_tax_tmp_2}
done < ${blastn_tax_tmp_1}

#get lineage information
eval ${ON}

#progress check
echo "Getting taxonomic lineage information"

taxonkit lineage -d $'\t' -i 3 ${blastn_tax_tmp_2} >> ${blastn_tax}
conda deactivate

#remove temp file
rm ${blastn_tax_tmp_1}
rm ${blastn_tax_tmp_2}

