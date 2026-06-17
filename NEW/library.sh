#!/bin/bash
  FROM=""
  TO=""
OUT=""

  PWD=$(pwd)
  STAMP=$(date +%Y-%m-%d_%H-%M-%S)


  # TERMINAL COLORS -----------------------------------------------------------------
  NONE='\033[00m'
  RED='\033[01;31m'
  GREEN='\033[01;32m'
  YELLOW='\033[01;33m'
  BLACK='\033[30m'
  BLUE='\033[34m'
  VIOLET='\033[35m'
  CYAN='\033[36m'
  GREY='\033[37m'



# sort_lines will sort log lines from different files with timestamps
sort_lines () {
  cat $FROM > $TO
  sort -t:  -k2 -k3 $TO > $OUT
}

search_word () {
  grep -ri "$WORD" $FILE
}