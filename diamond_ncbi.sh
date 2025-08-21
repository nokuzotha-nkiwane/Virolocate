#!/bin/env bash

#load module
module diamond

# variables and directories
wdir="/analyses/users/nokuzothan/disc_pipe"
cdir="${wdir}/init_tools/diamond"
input_reads_dir="${wdir}/init_tools/megahit/output/default"
db="${wdir}/ncbidb/viral/refseq/viral.1.protein.faa"
output="${cdir}/output/NCBI"
threads=$((`/bin/nproc` -2))

#clear existing output directory if any, make new output directory 
if [[ -e $output ]]; then
  rm -rf ${output} 
fi
mkdir -p -m a=rwx ${output}

#make diamond protein database
diamond makedb --in ${db} -d ${output}/nr

#loop through each of the files created in megahit output directory to find final.congtigs.fa files and run diamond
for folder in ls ${input_reads_dir}/*; do

  if [[ -d ${folder} ]]; then
    sample=$(basename ${folder})
    contigs=${folder}/sample.contigs.fa


    #alignment using blastx
    if [[ -f ${contigs} ]]; then
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
