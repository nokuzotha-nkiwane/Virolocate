#!/bin/env bash

#load module
module diamond

# variables and directories
wdir="/analyses/users/nokuzothan/disc_pipe"
cdir="${wdir}/init_tools/diamond"
input_reads_dir="${wdir}/init_tools/megahit/output/default"
db="${wdir}/init_tools/ncbi_fasta.faa"
output="${cdir}/output/NCBI"
tmp_db="${output}/nt.tmp"
threads=$((`/bin/nproc` -2))

#clear existing output directory if any, make new output directory 
if [[ -e $output ]]; then
  rm -rf ${output} 
fi
mkdir -p -m a=rwx ${output}

# #filter full nr database for viral sequences
# > ${tmp_db}
# while read -r LN;do
#   if [[ ${LN} == ">" ]]; then
#     echo "" >> ${tmp_db}
#   fi
  
#   echo -e -n "${LN}\t" >> ${tmp_db}
# done < ${db}





while read -r virus; do
    awk -v name="${virus}" '
        BEGIN {IGNORECASE=1}
        /^>/ {ON = index($0, name) > 0}
        ON {print}
    ' ${db} >> ncbi_fasta
done < virus.txt


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
