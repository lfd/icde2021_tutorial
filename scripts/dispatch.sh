#! /usr/bin/env bash

# e.g.,
# bash dispatch.sh 0.1 polite 25 x86

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 scalefactor scenario iterations label"
    exit 2
fi

scalefactor=$1      ## set TPC-H scale factor, e.g., 0.1 or 0.2
scenario=$2         ## polite or impolite
iterations=$3       ## number of iterations per query
label=$4            ## provide some identification label, e.g., "x86"

# Ensure data has been generated with this scale factor.

FILE=db/sf${scalefactor}/TPC-H.db
if [ ! -f "$FILE" ]; then
    echo "File $FILE does not exist. Did you run prepare_data.sh?"
	exit
fi

OUTDIR="res_SF-${scalefactor}_scenario-${scenario}_${label}/"

if [ -f "arguments.sh" ]; then
    . arguments.sh
else
    declare -A arguments=()
fi

rm -rf ${OUTDIR};
mkdir -p ${OUTDIR};

bin/latency db/sf$1/TPC-H.db queries.${scenario} ${iterations} \
	    1 2 3 4 5 6 7 8 9 10 11 12 14 15 16 18 19 21 | tee ${OUTDIR}/results.csv
