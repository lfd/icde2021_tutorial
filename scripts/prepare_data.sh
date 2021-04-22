#!/usr/bin/env bash

# Copyright 2021, Stefanie Scherzinger <stefanie.scherzinger@uni-passau.de>
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
# SPDX-License-Identifier: FSFAP

# Create a directory for SQLITE database instances.
mkdir -p db
rm -rf db/sf*


mkdir -p db/sf0.1
mkdir -p db/sf0.2

# SF 0.1
cd TPCH-sqlite
make clean
SCALE_FACTOR=0.1 make

mv TPC-H.db ../db/sf0.1

# SF 0.2
make clean
SCALE_FACTOR=0.2 make

mv TPC-H.db ../db/sf0.2
