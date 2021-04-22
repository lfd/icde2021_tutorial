#! /usr/bin/env bash
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
# SPDX-License-Identifier: FSFAP

# Superordinate dispatcher. Given a label that identifies
# the measuring host, run a set of polite and impolite measurements
# with standard settings (scale factor 0.1, 25 iterations per query)

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 label"
    exit 2
fi

./dispatch.sh 0.1 polite 25 $1
./dispatch.sh 0.1 impolite 25 $1
