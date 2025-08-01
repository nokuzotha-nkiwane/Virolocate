#!/bin/env bash

#load module
module diamond

# variables and directories
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools"
current_dir="${wdir}/diamond"
input_reads_dir="${wdir}/megahit/output/default"
zipped_proteins="${current_dir}/input/U-RVDBv30.0-prot.fasta.xz"
output="${current_dir}/output"
threads=$((`/bin/nproc` -2))

#clear existing output directory if any, make new output directory 
if [[ -e $output ]]; then
  rm -rf ${output} 
fi
mkdir -p -m a=rwx ${output}

#make diamond protein database
unxz -k ${zipped_proteins}
input_proteins=${zipped_proteins%.xz}
diamond makedb --in ${input_proteins} -d ${output}/nr

#loop through each of the files created in megahit output directory to find final.contigs.fa files and run diamond
for folder in ${input_reads_dir}/*; do

  if [[ -d ${folder} ]]; then
    sample=$(basename ${folder})
    contigs=${folder}/final.contigs.fa


    #alignment using blastx
    if [[ -f ${contigs} ]]; then
    sample_out=${output}/${sample}_rvdb.matches.m8
    diamond blastx -d ${output}/nr.dmnd -q ${contigs} -o ${sample_out} --threads ${threads} -f 6

    else 
      echo "Contigs file for ${sample} not found."
    fi
  fi
done
