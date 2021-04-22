#! /usr/bin/env bash

# Copyright 2021, Wolfgang Mauerer <wolfgang.mauerer@othr.de>
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
# SPDX-License-Identifier: FSFAP

# Run a sequence of runtime/latency measurements over the set
# of TPC-H queries defined below, for a given scale factor,
# and a given database mindset (polite or impolite)
# Each query is measured <iterations> times
# The <label> is used to uniquely identify the measurement

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 scalefactor scenario iterations label"
    exit 2
fi

scalefactor=$1      ## set TPC-H scale factor, e.g., 0.1 or 0.2
scenario=$2         ## database mood: polite or impolite
iterations=$3       ## number of iterations per query
label=$4            ## provide some identification label, e.g., "x86"

# Ensure data have been generated with this scale factor.
if [ ! -f "db/sf${scalefactor}/TPC-H.db" ]; then
    echo "Database db/sf${scalefactor}/TPC-H.db does not exist. Did you run prepare_data.sh?"
    exit
fi

OUTDIR="results/res_SF-${scalefactor}_scenario-${scenario}_${label}/"

if [ -f "arguments.sh" ]; then
    . arguments.sh
else
    declare -A arguments=()
fi

rm -rf ${OUTDIR};
mkdir -p ${OUTDIR}/config;

# Rum the acutual benchmark. We omit TPC-H queries 13,17,20,
# and 22 because their runtime much exceeds that of all other
# queries, and does not add additional insights to the mix --
# except making measurements harder to visualise because of
# greatly differing scales
bin/latency db/sf${scalefactor}/TPC-H.db queries.${scenario} ${iterations} \
	    1 2 3 4 5 6 7 8 9 10 11 12 14 15 16 18 19 21 | tee ${OUTDIR}/results.csv

# Save characteristics of the measuring system
for file in kconfig.gz cmdline cpuinfo modules cgroups; do
    if [ -f "${file}" ]; then
	cp /proc/${file} ${OUTDIR}/config/
    fi;
done
