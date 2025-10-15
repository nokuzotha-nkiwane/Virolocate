#!/bin/env bash

#load module
module diamond

# variables and directories
wdir="/analyses/users/nokuzothan/disc_pipe"
input_reads_dir="${wdir}/init_tools/diamond/output/blastn.fasta"
db="${wdir}/ncbidb/fasta/nr.faa"
output="${wdir}/init_tools/blastx_nr/output"
threads=$((`/bin/nproc` -2))

#clear existing output directory if any, make new output directory 
if [[ -e $output ]]; then
  rm -rf ${output} 
fi
mkdir -p ${output}


#diamond run on extracted contigs
if [[ -s ${input_reads_dir} ]]; then
  #progress check
  echo "Making Diamond Blastx database using nr database"

  #make diamond protein database
  diamond makedb --in ${db} -d ${output}/nr

  #progress check
  echo "Running diamond blastx"
  
  #diamond blastx run
  diamond blastx -d ${output}/nr.dmnd \
    --query ${input_reads_dir} \
    --out ${out_file} \
    --threads ${threads} \
    --evalue 1E-5 \
    --outfmt 6 \
    --id 80 \
    --strand both \
    --unal 0 \
    --mp-init 

else 
  echo "Contigs file for samples not found or is empty."
fi



exit 0