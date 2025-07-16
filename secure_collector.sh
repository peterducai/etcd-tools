#!/bin/bash

LOWLIMIT=1000

WARNINGS=(
    'apply request took too long'
    'leader changed'
    'nexpected watch close'
    'context deadline exceeded'
    'error on the server'
    'timeout'
    'failed'
)

#grep -inR "sample"

# cd $PWD
cd $1

for str in "${WARNINGS[@]}"; do
  echo -e ""
  echo -e "[$str] -----------------"
  grep -cinR "$str" | grep -v ':0$' |sort -t':' -n -k2 | tac |head -10
  #grep -cinR "$str" | grep -v ':0$' | grep -Eo '[0-9]+$'

  # if [[ $a -gt 50 ]]; then
  #   #...
  # fi
done