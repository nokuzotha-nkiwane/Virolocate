#!/bin/env bash

#load modules
ON="module miniconda && conda activate bowtie2"
eval ${ON}

#directories used
input_reads="/analyses/users/nokuzothan/disc_pipe/init_tools/fastp_test/output"
input_contigs="/analyses/users/nokuzothan/disc_pipe/init_tools/megahit/output/default/K058762_S14"
index_base="/analyses/users/nokuzothan/disc_pipe/init_tools/bowtie/index_K058762_S14/final_contigs"
output="/analyses/users/nokuzothan/disc_pipe/init_tools/bowtie/output"

#loop to get base name
for file in ${input_reads}/K058762_S14__R1_001_out.fastq;do
	file_name=$(basename "$file")
	id=${file_name%%__R1_001_out.fastq}
	R1=${input_reads}/${id}__R1_001_out.fastq
	R2=${input_reads}/${id}__R2_001_out.fastq

	#make output files
	unaligned="${output}/${id}_unaligned.fastq"
	sam="${output}/${id}.sam"
	
	#make index files
	contigs="${input_contigs}/final.contigs.fa"
	bowtie2-build ${contigs} ${index_base}
	index=${index_base}
done

#bowtie run
bowtie2 --phred33 -p 6 --un-conc ${unaligned} -x ${index} -1 ${R1} -2 ${R2} -S ${sam}




###corrected with TJ's script as template
#!/bin/env bash

#load modules
ON="module miniconda && conda activate bowtie2"
eval ${ON}

#check threads and assign n-2 to ${THR} a
THR=$((`/bin/nproc` -2))
MEM=`free -g | grep 'Mem:' | awk '{print $7}'`
NFILES=5
