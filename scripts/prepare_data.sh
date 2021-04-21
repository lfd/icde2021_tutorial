#!/usr/bin/env bash

# Create a directory for SQLITE database instances.
mkdir -p db
rm -rf db/sf*


mkdir -p db/sf0.1
mkdir -p db/sf0.2

# SF 0.1
cd $HOME/TPCH-sqlite
make clean
SCALE_FACTOR=0.1 make

mv TPC-H.db $HOME/db/sf0.1

# SF 0.2
make clean
SCALE_FACTOR=0.2 make

mv TPC-H.db $HOME/db/sf0.2
