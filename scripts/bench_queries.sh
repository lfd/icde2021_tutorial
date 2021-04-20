#MIT License

#Copyright (c) 2020 Timur Safin

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

#!/usr/bin/env bash

function check_q {
	local query=queries/query$i.sql
	(      
    	echo -n -e "$i\t"
	    (echo ".timer ON"; cat $query) | bin/sqshell db/sf$1/TPC-H.db | tail -n1 | awk -e '{OFS="\t"; print $4,$6,$8;}'
	)
}

# e.g., bench_queries.sh 0.1 impolite
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 scalefactor scenario"
    exit 2
fi

scalefactor=$1
scenario=$2

echo -e "query\treal\tuser\tsys"

for i in 1 2 3 4 5 6 7 8 9 10 11 12 14 15 16 18 19 21; do
	check_q ${scalefactor} ${scenario} $i
	check_q ${scalefactor} ${scenario} $i
	check_q ${scalefactor} ${scenario} $i
done
