#! /usr/bin/env bash

# e.g.,
# bash dispatch.sh 0.1 polite x86 

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 scalefactor scenario label"
    exit 2
fi

scalefactor=$1      ## set TPC-H scale factor, e.g., 0.1 or 0.2
scenario=$2         ## polite or impolite
label=$3            ## provide some identification label, e.g., "x86"
LOGCOUNT=1

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

bin/latency db/sf$1/TPC-H.db queries.${scenario} 10 1 2 3 4 5 6 7 8 9 10 11 12 14 15 16 18 19 21 | tee ${OUTDIR}/results.csv
