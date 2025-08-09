#!/bin/env bash

#load modules
module ncbi

#directories
wdir="/analyses/users/nokuzothan/disc_pipe/init_tools"
mega_conts="${wdir}/megahit/output/default"
rv_dir="${wdir}/diamond/output/RVDB"
blastn_out="${wdir}/rvdb_blastn/output"
blast_contigs="${blastn_out}/blast_fastas"
final_out="${blastn_out}/blastn_results"
threads=$((`/bin/nproc` -2))

#create output for blastn
if [[ -e ${blastn_out} ]]; then
    rm -rf ${blastn_out}
fi
mkdir -p ${blastn_out}

#make blast_fastas subdirectory in blastn output folder
mkdir -p ${blast_contigs}

#make blastn_results subdirectory in blastn output folder
mkdir -p ${final_out}


#if working with RVDB, check if RVDB folder exists so if it doesnt only run ncbi part
if [[ ! -e ${rv_dir} ]]; then 
    echo "No RVDB folder exists. Searching for NCBI folder..."
else 
    echo "Using RVDB folder for blastn file preparation"

    #clear existing accession id file and database fasta before rerun
    acc_ids=${blastn_out}/acc_ids.txt
    > ${acc_ids}
    > ${blastn_out}/rvdb_blastn.fasta
    
    

    #get contig matches from m8 files
    for contig in ${rv_dir}/*.m8;do

        #check if file exists
        if [[ ! -f "${contig}" ]]; then
            echo "matches.m8 file for ${contig} in RVDB not found."

        else
            base=`basename ${contig}`
            sample=${base%_rvdb.matches.m8}

            #clear existing unique match and fasta output files before rerun
            u_match_out=${blastn_out}/u_${sample}_contig_matches.txt
            output_fa=${blast_contigs}/${sample}_bl_contigs.fa
    
            > ${u_match_out}
            > ${output_fa}
            
            #get unique contig matches
            cat ${contig} | awk '{print $1}' > ${u_match_out}
            sort -u ${u_match_out} -o ${u_match_out}

            #get accession ids
            cat ${contig} | awk '{print $3}' | cut -d "|" -f5 >> ${acc_ids}
            sort -u ${acc_ids} -o ${acc_ids}

            #progress check
            echo "Starting contig matching for ${sample}" 

            ##find the contig matches in the final.contigs.fa file
            fin_fasta=${mega_conts}/${sample}/final.contigs.fa

            while read -r hit; do
                awk -v contig=">${hit} " '
                    index($0, contig) == 1 {print; ON=1; next}
                    ON && /^>/ {exit}
                    ON {print}
                ' ${fin_fasta} >> ${output_fa}

                #progress check
                echo "Sequence for ${hit} found"
            done < ${u_match_out}


            #progress check
            echo "Contig matching for ${sample} done"
        fi
    done


    #download fastas of the accession ids parsed from diamond output
    function fasta_dwnl {
        acc_id=$1
        output=$2

        url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${acc_id}&rettype=fasta&retmode=text" 
        curl -N -# ${url} >> ${output}
    }

    #function call to download fastas for rvdb database
    while read -r acc_id;do
        fasta_dwnl ${acc_id} ${blastn_out}/rvdb_blastn.fasta
    done < ${acc_ids}

    echo "RVDB blastn fasta file download complete"

    #clear previous database data
    rm -f ${blastn_out}/rvdb_db.*

    #make rvdb database
    makeblastdb -in ${blastn_out}/rvdb_blastn.fasta -dbtype nucl -out ${blastn_out}/rvdb_db

    for file in ${blast_contigs}/*.fa; do
        base=$(basename "${file}")
        sample=${base%_bl_contigs.fa}

        > ${final_out}/${sample}_blastn_out.tsv

        if [[ -s "${file}" ]]; then
            blastn -query ${file} \
            -db ${blastn_out}/rvdb_db \
            -out ${final_out}/${sample}_blastn_out.tsv \
            -strand both \
            -num_threads ${threads} \
            -evalue 1E-5 \
            -outfmt "6 qseqid qlen sseqid stitle pident length qstart qend evalue bitscore" \
            -perc_identity 80
        
        else
            echo "No sequences for ${sample}, skipping blastn."
        fi
    done

fi

exit