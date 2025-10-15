#!/bin/env bash

module miniconda
conda activate fastp

#first get the SRA ID as a variable using %%
for file in *_1.fastq

do
id=${file%%_1.fastq}

R1=${id}_1.fastq
R2=${id}_2.fastq

P1=${id}_1_out.fastq
P2=${id}_2_out.fastq

fastp -V --failed_out ${id}_failed_reads.fastq -i $R1 -o $P1 -I $R2 -O $P2 --detect_adapter_for_pe --html ${id}_fastp.html --json ${id}_fastp.json
done



##Corrected because module miniconda might not have been loading right

#!/bin/env bash

source /analyses/software/programs/miniconda/3/etc/profile.d/conda.sh
conda activate fastp

#first get the SRA ID as a variable using %%
for file in *_1.fastq

do
id=${file%%_1.fastq}

R1=${id}_1.fastq
R2=${id}_2.fastq

P1=${id}_1_out.fastq
P2=${id}_2_out.fastq

fastp -V --failed_out ${id}_failed_reads.fastq -i $R1 -o $P1 -I $R2 -O $P2 --detect_adapter_for_pe --html ${id}_fastp.html --json ${id}_fastp.json
done


###final script

#!/bin/env bash

ON_1="module miniconda && conda activate fastp"
ON_2="conda activate fastqc"
OFF="conda deactivate"
eval ${ON_1}

input="/analyses/users/nokuzothan/disc_pipe/init_tools/fastp_test/input"
output="/analyses/users/nokuzothan/disc_pipe/init_tools/fastp_test/output"
pretrim="/analyses/users/nokuzothan/disc_pipe/init_tools/fastp_test/pretrim"

#first get the SRA ID as a variable using %%
for file in $input/*_R1_001.fastq;

do
file_name=$(basename "$file")
id=${file_name%%_R1_001.fastq}

#input file name
R1="${input}/${id}_R1_001.fastq"
R2="${input}/${id}_R2_001.fastq"

#output file name
P1="${output}/${id}__R1_001_out.fastq"
P2="${output}/${id}__R2_001_out.fastq"

#one file created for each read pair
failed="${output}/${id}_failed_reads.fastq"
HTML="${output}/${id}_fastp.html"
JSON="${output}/${id}_fastp.json"

#fastp run 
fastp -V --failed_out ${failed} --detect_adapter_for_pe --html ${HTML} --json ${JSON} -w 8 -i ${R1} -o ${P1} -I ${R2} -O ${P2} 
done

eval ${OFF}

#multiqc run that takes inpput from pretrim and output quality control
eval $ON_2
multiqc "$output" "$pretrim" -o "$output"

echo "FastP run completed successfully ;-)"




adapters="TruSeq3-PE.fa"

-- adapter_fasta $adapters