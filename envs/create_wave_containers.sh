#!/bin/env bash
set -uex

folder="../modules/local"

for file in "${folder}"/**/*.yml; do
    echo "Building container from ${file}"
    container=$(wave --conda-file "${file}")
    echo "${file} -> ${container}"
done