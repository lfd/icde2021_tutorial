#! /usr/bin/env bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 label"
    exit 2
fi

./dispatch.sh 0.1 polite 25 $1
./dispatch.sh 0.1 impolite 25 $1
