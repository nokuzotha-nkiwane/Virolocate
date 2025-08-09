#!/bin/env bash

#load module
module diamond

# variables and directories
wdir="/analyses/users/nokuzothan/disc_pipe"
cdir="${wdir}/init_tools/diamond"
input_reads_dir="${wdir}/init_tools/megahit/output/default"
db="${wdir}/ncbidb/RVDB/v30.0/U-RVDBv30.0-prot.fasta"
output="${cdir}/output/RVDB"
threads=$((`/bin/nproc` -2))

#clear existing output directory if any, make new output directory 
if [[ -e $output ]]; then
  rm -rf ${output} 
fi
mkdir -p ${output}

#make diamond protein database
diamond makedb --in ${db} -d ${output}/nr

#loop through each of the files created in megahit output directory to find final.contigs.fa files and run diamond
for folder in ${input_reads_dir}/*; do

  if [[ -d ${folder} ]]; then
    sample=$(basename ${folder})
    contigs=${folder}/final.contigs.fa


    #alignment using blastx (exclude --min-score because it overrides the evalue (acc. to manual))
    if [[ -f ${contigs} ]]; then
    sample_out=${output}/${sample}_rvdb.matches.m8
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


its been a while where have you been?
