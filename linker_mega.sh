#!/bin/env bash

input="/analyses/users/nokuzothan/disc_pipe/init_tools/fastp_test/output"
output="/analyses/users/nokuzothan/disc_pipe/init_tools/megahit/input"

for file in ${input}/*_out.fastq;

do 
	file_name=$(basename "$file")
	ln -s "$file" "${output}/${file_name}"
done

echo "Files linked!"