#!/bin/env bash

#load module
module diamond

# variables and directories
wdir="/analyses/users/nokuzothan/disc_pipe"
cdir="${wdir}/init_tools/diamond"
input_reads_dir="${wdir}/init_tools/megahit/output/default"
db="${wdir}/ncbidb/fasta/nr.faa"
output="${cdir}/output/NCBI"
tmp_db="${output}/nt.tmp"
threads=$((`/bin/nproc` -2))

#clear existing output directory if any, make new output directory 
if [[ -e $output ]]; then
  rm -rf ${output} 
fi
mkdir -p -m a=rwx ${output}

while read -r virus; do
    awk -v name="${virus}" '
        BEGIN {IGNORECASE=1}
        /^>/ {ON = index($0, name) > 0}
        ON {print}
    ' ${db} >> ncbi_fasta
done < virus.txt

# #downloading protein fasta sequences from genbank and making them one file 
# # Number of sequences per batch
# batch=50000

# # Step 1: Get total number of viral protein sequences
# total=$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=protein&term=txid10239[Organism]&rettype=count&retmode=text")
# echo "Total viral protein sequences: $total"

# # Step 2: Fetch in batches
# for start in $(seq 0 $batch $total); do
#     echo "Fetching sequences $start to $((start+batch-1))..."
#     curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&term=txid10239[Organism]&retstart=${start}&retmax=${batch}&rettype=fasta&retmode=text" >> ${db}
# done

# echo "Download complete. Sequences saved in ${db}"


#make diamond protein database
diamond makedb --in ${db} -d ${output}/nr

#loop through each of the files created in megahit output directory to find final.congtigs.fa files and run diamond
for folder in ls ${input_reads_dir}/*; do

  if [[ -d ${folder} ]]; then
    sample=$(basename ${folder})
    contigs=${folder}/sample.contigs.fa


    #alignment using blastx
    if [[ -s ${contigs} ]]; then
    sample_out=${output}/${sample}.matches.m8
    diamond blastx -d ${output}/nr.dmnd \
    -q ${contigs} \
    --out ${sample_out} \
    --threads ${threads} \
    --evalue 1E-5 \
    --outfmt 6 qseqid qlen sseqid stitle pident length evalue bitscore \
    --id 80 \
    --strand both \
    --unal 0 \
    --mp-init 

    else 
      echo "Contigs file for ${sample} not found."
    fi
  fi
done
