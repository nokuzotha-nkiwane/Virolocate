#!/bin/env bash

#directories
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools/diamond/output"
rv_dir="${wdir}/RVDB"
rv_ann="${rv_dir}/annotated"


#remove rv_ann folder if it exists
if [[ -e ${rv_ann} ]]; then
  rm -rf ${rv_ann} 
fi
mkdir -p ${rv_ann}

#take acc_id from diamond output file 
for matches in ${rv_dir}/*.m8;do
   cat ${matches} | awk '{print $2}' | cut -d "|" -f3 >> ${rv_ann}/acc_ids.txt
done

#sort and deduplicate acc_ids.txt
sort -u "${rv_ann}/acc_ids.txt" -o "${rv_ann}/unique_acc_ids.txt"

#function to download asn.1 info (taxonomy)
function taxon_dwnl() {
acc_id=$1
output=$2

#download from protein database because based on protein database reference
url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=${acc_id}&rettype=asn1&retmode=text" 

# curl -N -# ${url} > ${output}/${acc_id}.asn1
if curl -N -# ${url} > ${output}/${acc_id}.asn1; then
   echo "Downloaded ${acc_id}"
else
   echo "Failed: ${acc_id}" >> "${output}/failed_downloads.txt"
fi

}
export -f taxon_dwnl

#link to download fastas
while read -r acc_id;do
   taxon_dwnl ${acc_id} ${rv_ann}
done < "${rv_ann}/unique_acc_ids.txt"


#function for annotation parsing
function parsing {
   acc_id=$1
   asn_file=$2
   output=$3



   lineage=`grep 'lineage " ' ${file} | cut -d '"' -f2)`
   echo 
}
   

#function call for annotation parsing
for file in ${rv_ann}/*.asn1;do
   while read -r acc_id;do
   