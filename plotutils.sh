#!/bin/bash

STAMP=$(date +%Y-%m-%d_%H-%M-%S)

# args: etcd_member value2graph "data"
echo $3 | spline | graph -T svg -X "time" -Y "$2" > $1_$2.svg
#graph -T svg -X "time" -Y "$2" datafile > $1_$2.svg
#plot -T svg < $1_$2.meta > $1_$2.svg
#plot -T X test.meta