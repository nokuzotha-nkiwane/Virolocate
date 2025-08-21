#!/bin/env bash

#load modules
ON="module miniconda && conda activate megahit"
eval $ON

#directories
input="/analyses/users/nokuzothan/disc_pipe/init_tools/fastp_test/output"
output="/analyses/users/nokuzothan/disc_pipe/init_tools/megahit/output/default"

#remove output directory if already exists and make new one
if [[ -d ${output} ]]; then
	rm -rf ${output}
fi
mkdir -p ${output}

#run megahit
for file in ${input}/*__R1_001_out.fastq;do 

	file_name=$(basename "$file")
	id=${file_name%%__R1_001_out.fastq}
	
	R1=${input}/${id}__R1_001_out.fastq
	R2=${input}/${id}__R2_001_out.fastq

	megahit --verbose -t 10 -1 ${R1} -2 ${R2} -o ${output}/${id}

	#after megahit run, prepend sample name to contigs (allows easier tracking of which contigs came from which sample in downstream analysis)
	awk -v prefix="${id}:" '
        /^>/ {$0=">" prefix substr($0,2)} {print}
    ' ${output}/${id}/final.contigs.fa > ${output}/${id}/sample.contigs.fa

done

echo "Megahit assmebly completed successfully :-) and contigs named with sample name"
