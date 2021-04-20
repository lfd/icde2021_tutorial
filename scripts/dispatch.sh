#! /bin/bash

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


./bench_queries.sh ${scalefactor} ${scenario} | tee ${OUTDIR}/results.csv

exit

for i in queries/*.sql; do
    echo "hello query{$i}"
    echo -n "Executing query ${i} (`date "+%H:%M:%S"`): ";
    rm -rf ${OUTDIR}/${i};
    mkdir -p ${OUTDIR}/${i};
    dbt="linux/${dataset}${i} --log-count=${LOGCOUNT} --no-output --timeout=${duration} ${arguments['${i}']}"
	
    if [[ "${dataset}" == "finance" ]]; then
	dbt="${dbt} --iterations=50"
    fi;
	
    case "${scenario}" in
	fifo)
	    tsm="taskset --cpu-list ${taskset_meas}";
	    execstr="sudo chrt -f 98 ${dbt} > ${OUTDIR}/${i}/latencies.txt";
	    ;;
	shield)
	    sudo cset shield --cpu ${taskset_meas} --kthread=on;
	    tsm="";
	    execstr="sudo cset shield --exec -- ${dbt} 2>&1 | grep -v cset > ${OUTDIR}/${i}/latencies.txt";
	    ;;
	shield+fifo)
	    sudo cset shield --cpu ${taskset_meas} --kthread=on;
	    tsm="";
	    execstr="sudo cset shield --exec -- sudo chrt -f 98 ${dbt} 2>&1 | grep -v cset > ${OUTDIR}/${i}/latencies.txt";
	    ;;
	default)
	    tsm="taskset --cpu-list ${taskset_meas}"
	    execstr="${dbt} > ${OUTDIR}/${i}/latencies.txt";
	    ;;
	*)
	    echo "Scenario ${scenario} is not known!"
	    exit
	    ;;
    esac

    cmd="${tsm} ${execstr}"
	
    echo "Measurement summary" > ${OUTDIR}/${i}/info.txt
    ##	echo "# stressors: ${no_stressors}" > ${OUTDIR}/${i}/info.txt
    ##	echo "Time per stressor: ${stressor_timeout} [s]" >> ${OUTDIR}/${i}/info.txt
    echo "Taskset (load): ${taskset_load}" >> ${OUTDIR}/${i}/info.txt
    echo "Taskset (measurement): ${taskset_meas}" >> ${OUTDIR}/${i}/info.txt	
    echo "Kernel: `uname -a`" >> ${OUTDIR}/${i}/info.txt
    echo "Command: ${cmd}" >> ${OUTDIR}/${i}/info.txt
	
    if (( ${stress} > 0 )); then
	stress-ng --bsearch 0 --matrix 0 --zlib 0 --cache 0 --iomix 0 --timer 0  --metrics-brief --taskset ${taskset_load} -t ${duration} > ${OUTDIR}/${i}/stress-ng.log 2>&1 &
        PID=$!;
    fi;

  ##      timeout ${duration} bash -c "while true; do eval \"${cmd}\"; done";
    eval "${cmd}";
    echo -n "finished (`date "+%H:%M:%S"`). Stressors: ";
    if (( ${stress} > 0 )); then
	sudo kill -s SIGINT ${PID} > /dev/null 2>&1 # We need to send the signal as root because chrt and cset tasks run with root privileges
	wait ${PID};
    fi;
    echo "finished.";
    
    case ${scenario} in
	shield|shield+fifo)
	    sudo cset shield -r
	    ;;
	*)
	    ;;
    esac
done

rm -rf ${stressjob}