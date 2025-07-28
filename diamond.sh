#!/bin/env bash

#load module
module diamond

# variables and directories
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools"
current_dir="${wdir}/diamond"
input_reads_dir="${wdir}/megahit/output"
input_proteins="${current_dir}/input/protein_sequences.fasta"
output="${current_dir}/output"
threads=$((`/bin/nproc` -2))

#clear existing output directory if any, make new output directory 
rm -rf ${output}
mkdir -p -m a=rwx ${output}

#loop through each of the files created in megahit output directory to find final.congtigs.fa files
### Linking out Contigs
# remove only old .fasta symlinks
rm -f ${output}/*.fasta  

for folder in $(ls -dl ${input_reads_dir}/* | grep ^d | awk '{print $9}'); do
  file_name=`basename ${folder}`
  ln -s ${folder}/final.contigs.fa ${output}/${file_name}.fasta
done


#make diamond protein database
diamond makedb --in ${input_proteins} -d ${output}/nr

#alignment using blastx
for contigs in ${output}/*.fasta; do
sample=$(basename ${contigs} .fasta)
mkdir -p -m a=rwx "${output}/${sample}"
sample_out=${output}/${sample}

diamond blastx -d ${output}/nr.dmnd -q ${contigs} -o $sample_out/matches.m8 --threads ${threads} -f 6

done