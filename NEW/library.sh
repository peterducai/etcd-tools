#!/bin/bash

init_values () {
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
}


sort_lines ( $FROM, $TO) {
  cat $FROM > $TO   #$OUTPUT_PATH/etcd*.log > $OUTPUT_PATH/output_etcd_logs.log
  sort -t:  -k2 -k3 $TO > $OUT    #$OUTPUT_PATH/output_etcd_logs.log > $OUTPUT_PATH/sorted.tmp
}

search_word ($WORD, $FILE) {
  grep -ri "$WORD" $FILE
}