#!/usr/bin/env bash

# Create a directory for SQLITE database instances.
mkdir -p db
cd db
rm -rf sf*


mkdir -p sf0.1
mkdir -p sf0.2

# SF 0.1
cd ../git-repos/TPCH-sqlite
make clean
SCALE_FACTOR=0.1 make

mv TPC-H.db ../../db/sf0.1

# SF 0.2
make clean
SCALE_FACTOR=0.2 make

mv TPC-H.db ../../db/sf0.2



