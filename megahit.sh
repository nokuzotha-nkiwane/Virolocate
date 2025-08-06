#!/bin/env bash

ON="module miniconda && conda activate megahit"
eval $ON

input="/analyses/users/nokuzothan/disc_pipe/init_tools/fastp_test/output"
output="/analyses/users/nokuzothan/disc_pipe/init_tools/megahit/output/default"

for file in ${input}/*__R1_001_out.fastq;do 

	file_name=$(basename "$file")
	id=${file_name%%__R1_001_out.fastq}
	
	R1=${input}/${id}__R1_001_out.fastq
	R2=${input}/${id}__R2_001_out.fastq

	megahit --verbose -t 10 -1 ${R1} -2 ${R2} -o ${output}/${id}

done

echo "Megahit assmebly completed successfully :-)"


21, 27, 33

-meta flag for spades