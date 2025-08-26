#!/bin/env bash

for file in /analyses/users/nokuzothan/disc_pipe/init_data/*.fastq;

do
	ln -s "$file" .

done


