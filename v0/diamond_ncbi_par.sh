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

function blasting {
  contigs=$1
 
  #extract sample name
  name=`basename $(dirname ${contigs})`
  sample_out=${output}/${name}.matches.m8

  #blastx alignment
  if [[ -f ${contigs} ]]; then
  diamond blastx -d ${output}/nr.dmnd -q ${contigs} -o ${sample_out} --threads ${threads} -e 1E-5 -f 6 qseqid qlen sseqid stitle pident length evalue 

  else 
    echo "Contigs file for ${name} not found."
  fi
}
export -f blasting

#function call for alignment
ls ${input_reads_dir}/*/*.fasta | parallel -j 10 -n1 -I% "blasting %"


