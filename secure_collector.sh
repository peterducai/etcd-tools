#!/bin/bash


WARNINGS=(
    'apply request took too long'
    'leader changed'
)

#grep -inR "sample"

for str in "${WARNINGS[@]}"; do
  echo -e ""
  echo -e "[$str] -----------------"
  grep -cinR "$str"
done