#!/bin/bash

#PWD="/home/pducai/Downloads/must-gather.local.3496992070518267793"

WARNINGS=(
    'apply request took too long'
    'leader changed'
    'nexpected watch close'
    'context deadline exceeded'
    'error on the server'
)

#grep -inR "sample"

# cd $PWD
cd $1

for str in "${WARNINGS[@]}"; do
  echo -e ""
  echo -e "[$str] -----------------"
  grep -cinR "$str" | grep -v ':0$'
done