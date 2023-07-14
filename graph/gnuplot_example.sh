#!/bin/bash

gnuplot <<EOF
set term svg
set output "output.svg"
set key left top
plot '/tmp/test.dat' using 1:2 with lines title 'test1',\
	'/tmp/test.dat' using 1:3 with lines title 'test2',\
	'/tmp/test.dat' using 1:4 with lines title 'test3'
EOF


