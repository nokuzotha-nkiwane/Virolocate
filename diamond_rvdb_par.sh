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
if [[ -e ${output} ]]; then
  rm -rf ${output} 
fi
mkdir -p ${output}

#make diamond protein database
diamond makedb --in ${db} -d ${output}/nr

#loop through each of the files created in megahit output directory to find final.contigs.fa files and run diamond

function blasting() {
  contigs=$1
  output=$2
 
  #extract sample name
  name=`basename $(dirname ${contigs})`
  sample_out=${output}/${name}_rvdb.matches.m8

  #blastx alignment
  if [[ -f ${contigs} ]]; then
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
    echo "Contigs file for ${name} not found."
  fi
}
export -f blasting

#function call for alignment
ls ${input_reads_dir}/*/*.fa | parallel -j 10 -n1 -I% "blasting % ${output}"
