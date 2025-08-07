#!/bin/env bash

# #load modules
ON="module miniconda && conda activate megahit"
eval ${ON}
module diamond

#directories
wdir="/analyses/users/nokuzothan/disc_pipe/"
prot_db="${wdir}/ncbidb/RVDB/v30.0/U-RVDBv30.0-prot.fasta"
nuc_db="${wdir}/ncbidb/RVDB/v30.0/U-RVDBvCurrent.fasta" #nucleotide therefore current also check what you cut 
play="${wdir}/playground"
output1="${play}/fastas_1"
output2="${play}/megahit"
output3="${play}/diamond"
output4="${play}/asn1"

# #make playground directory unless it exists
mkdir -p ${play}

#remove output1 folder if it exists
if [[ -e ${output1} ]]; then
  rm -rf ${output1} 
fi
mkdir -p ${output1}

#take acc_id from RVDB nucleotide file (up to 10 acc_ids) (taking nucleotide because as much as diamond works with proteins, we would have sequences the nucleotide seq)
cat ${nuc_db} | grep ">" | cut -d "|" -f3 | head -n 10 >> ${output1}/acc_ids.txt

#function to download fastas
function fasta_dwnl {
acc_id=$1
output=$2

url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${acc_id}&rettype=fasta&retmode=text" 

curl -N -# ${url} >> ${output}/${acc_id}.fasta
echo "Fasta for ${acc_id} found."

}
export -f fasta_dwnl

#remove output2 folder if it exists
if [[ -e ${output2} ]]; then
  rm -rf ${output2} 
fi
mkdir -p ${output2}

#call to download fastas
while read -r acc_id;do
   fasta_dwnl ${acc_id} ${output1}
done < ${output1}/acc_ids.txt

#megahit
function assemble {
    fasta=$1
    output=$2

    base=`basename ${fasta}`
    name=${base%.fasta}

    out=${output}/${name}
    megahit --verbose -t 10 -r ${fasta} -o ${out}
}

#call to run megahit
for fasta_file in ${output1}/*.fasta; do
    assemble ${fasta_file} ${output2}
done


#remove output3 folder if it exists
if [[ -e ${output3} ]]; then
  rm -rf ${output3} 
fi
mkdir -p ${output3}

#make diamond protein database
diamond makedb --in ${prot_db} -d ${output3}/nr

#loop through each of the files created in megahit output directory to find final.contigs.fa files and run diamond

function blasting {
  contigs=$1
  output=$2
 
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
#ls ${output2}/*/final.contigs.fa | parallel -j 10 -n1 -I% "blasting % ${output3}/"

for contigs in ${output2}/*/final.contigs.fa;do
   blasting ${contigs} ${output3}
done


#remove output4 folder if it exists
if [[ -e ${output4} ]]; then
  rm -rf ${output4} 
fi
mkdir -p ${output4}

#take acc_id from diamond output file 
cat ${input} | grep ">" | cut -d "|" -f3 | head -n 10 >> ${output4}/acc_ids.txt

#function to download asn.1 info (taxonomy)
function taxon_dwnl() {
acc_id=$1
output=$2

#download from protein database because based on protein database reference
url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=${acc_id}&rettype=asn1&retmode=text" 

curl -N -# ${url} > ${output}/${acc_id}.asn1

}
export -f taxon_dwnl

#link to download fastas
while read -r acc_id;do
   taxon_dwnl ${acc_id} ${output4}
done < ${output4}/acc_ids.txt





#  cat $file | awk '{print $2}' | cut -d '|' -f5  >>${ann_dir}/acc_id_list.txt

#   cat $file | cut -d ',' -f2 | awk '{print $2}' >>${ann_dir}/acc_id_list.txt

# cat K058681_S32_rvdb.matches.m8 | awk '{print $2}' | cut -d '|' -f5  >> acc_id_list.txt
