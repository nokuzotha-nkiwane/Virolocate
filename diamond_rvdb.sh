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
mkdir -p -m a=rwx ${output}

#make diamond protein database
diamond makedb --in ${db} -d ${output}/nr

#loop through each of the files created in megahit output directory to find final.contigs.fa files and run diamond
for folder in (ls ${input_reads_dir}/*); do

  if [[ -d ${folder} ]]; then
    sample=$(basename ${folder})
    contigs=${folder}/final.contigs.fa


    #alignment using blastx
    if [[ -f ${contigs} ]]; then
    sample_out=${output}/${sample}_rvdb.matches.m8
    diamond blastx -d ${output}/nr.dmnd -q ${contigs} -o ${sample_out} --threads ${threads} -e 1E-5 -f 6 qseqid qlen sseqid stitle pident length evalue 

    else 
      echo "Contigs file for ${sample} not found."
    fi
  fi
done
