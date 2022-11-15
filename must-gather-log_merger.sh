#!/bin/bash

# Author : Peter Ducai <peter.ducai@gmail.com>
# License : GPL3



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

color=('\033[34m' '\033[37m' '\033[01;31m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m')

#TIMELINE='2022-10-13T'
#TIMELINE='2022-10-13T02'
STAMP=$(date +%Y-%m-%d_%H-%M-%S)
ETCD_NS='openshift-etcd'
MUST_PATH=$1
ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA

rm -rf $OUTPUT_PATH
mkdir -p $OUTPUT_PATH



# PARSER --------------------------------------------------------------------------

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -a|--my-boolean-flag)
      MY_FLAG=0
      shift
      ;;
    -b|--my-flag-with-argument)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        MY_FLAG_ARG=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

#---------------------------------------------------------------------------------


echo -e "OVERLOADED = leader failed to send out heartbeat on time; took too long, leader is overloaded likely from slow disk"
echo -e ""





# MAIN --------------------------

cd $MUST_PATH
cd $(echo */)
cd namespaces/$ETCD_NS/pods

etcd_check() {    #  elected leader
    i=0
    
    for member in $(ls |grep -v "revision"|grep -v "quorum"); do
      echo "processing $member"
      echo -e "" > $OUTPUT_PATH/$member.log
      cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'likely'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} failed to send out heartbeat on time; took too long, leader is overloaded likely from slow disk     [$member] !!!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      # cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'took too long'|cut -d ' ' -f1| \
        # xargs -I {} echo -e "{} took too long  [$member]" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'leader changed'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} took too long due to LEADER changed [$member] !" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'elected leader'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} LEADER changed [$member] !!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'clock'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} NTP clock difference [$member] !!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'buffer'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} dropped internal Raft message since sending buffer is full (overloaded network) [$member] !!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      #increment color
      i=$((${i}+1))
    done
    i=0
    cat $OUTPUT_PATH/etcd*.log > $OUTPUT_PATH/output_etcd_logs.log
    sort -t:  -k2 -k3 $OUTPUT_PATH/output_etcd_logs.log > $OUTPUT_PATH/sorted.tmp
    cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_etcd_logs.log
}

router_check() {
    i=0
    
    for router in $(ls); do
      echo "processing $router"
      echo -e "" > $OUTPUT_PATH/$router.log
      cat $router/router/router/logs/current.log |grep "$TIMELINE"|grep 'Unexpected watch close'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} Unexpected watch close     [$router] !!!" | while read -r line; do echo -e "$YELLOW$line$NONE" >> $OUTPUT_PATH/$router.log; done
      # cat $member/router/router/logs/current.log |grep "$TIMELINE"|grep 'took too long'|cut -d ' ' -f1| \
        # xargs -I {} echo -e "{} took too long  [$router]" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$router.log; done
      # cat $member/router/router/logs/current.log |grep "$TIMELINE"|grep 'leader'|cut -d ' ' -f1| \
      #   xargs -I {} echo -e "{} LEADER changed [$router] !" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$router.log; done
      # cat $member/router/router/logs/current.log |grep "$TIMELINE"|grep 'clock'|cut -d ' ' -f1| \
      #   xargs -I {} echo -e "{} NTP clock difference [$router] !!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$router.log; done
      # cat $member/router/router/logs/current.log |grep "$TIMELINE"|grep 'buffer'|cut -d ' ' -f1| \
      #   xargs -I {} echo -e "{} BUFF [$router] !!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$router.log; done
      #increment color
      i=$((${i}+1))
    done
    i=0
    cat $OUTPUT_PATH/router*.log > $OUTPUT_PATH/output_router_logs.log
    sort -t:  -k2 -k3 $OUTPUT_PATH/output_router_logs.log > $OUTPUT_PATH/sorted.tmp
    cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_router_logs.log
}

stackinfra_check() {
    i=0
    
    for keepalived in $(ls |grep master|grep -v "coredns"|grep -v "haproxy"); do
      echo "processing $keepalived"
      echo -e "" > $OUTPUT_PATH/$keepalived.log
      cat $keepalived/keepalived/keepalived/logs/current.log |grep "$TIMELINE"|grep 'Entering'| \
        xargs -I {} echo -e "{}      [$keepalived] !!!" | while read -r line; do echo -e "$YELLOW$line$NONE" >> $OUTPUT_PATH/$keepalived.log; done
      #increment color
      i=$((${i}+1))
    done
    i=0
    cat $OUTPUT_PATH/keepalived*.log > $OUTPUT_PATH/output_keepalived_logs.log
    sort -t:  -k2 -k3 $OUTPUT_PATH/output_keepalived_logs.log > $OUTPUT_PATH/sorted.tmp
    cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_keepalived_logs.log
}

kube-apiserver_check() {
    i=0
    
    for kubeapiserver in $(ls |grep master|grep -v "coredns"|grep -v "haproxy"); do
      echo "processing $kubeapiserver"
      echo -e "" > $OUTPUT_PATH/$kubeapiserver.log
      cat $kubeapiserver/kube-apiserver/kube-apiserver/logs/current.log |grep "$TIMELINE"|grep -i 'error'| \
        xargs -I {} echo -e "{}      [$kubeapiserver] !!!" | while read -r line; do echo -e "$YELLOW$line$NONE" >> $OUTPUT_PATH/$kubeapiserver.log; done
      #increment color
      i=$((${i}+1))
    done
    i=0
    cat $OUTPUT_PATH/kube-apiserver*.log > $OUTPUT_PATH/output_kube-apiserver_logs.log
    sort -t:  -k2 -k3 $OUTPUT_PATH/output_kube-apiserver_logs.log > $OUTPUT_PATH/sorted.tmp
    cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_kube-apiserver_logs.log
}

haproxy_check() {
    i=0
    
    for haproxy in $(ls |grep haproxy|grep -v "coredns"|grep -v "kube-apiserver"); do
      echo "processing $haproxy"
      echo -e "" > $OUTPUT_PATH/$haproxy.log
      cat $haproxy/haproxy/haproxy/logs/current.log |grep "$TIMELINE"|grep -i 'error'| \
        xargs -I {} echo -e "{}      [$haproxy] !!!" | while read -r line; do echo -e "$YELLOW$line$NONE" >> $OUTPUT_PATH/$haproxy.log; done
      #increment color
      i=$((${i}+1))
    done
    i=0
    cat $OUTPUT_PATH/kube-apiserver*.log > $OUTPUT_PATH/output_haproxy_logs.log
    sort -t:  -k2 -k3 $OUTPUT_PATH/output_haproxy_logs.log > $OUTPUT_PATH/sorted.tmp
    cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_haproxy_logs.log
}


etcd_check

cd ../../..
cd namespaces/openshift-ingress/pods

router_check

cd ../../..
cd namespaces/openshift-openstack-infra/pods

stackinfra_check
haproxy_check

cd ../../..
cd namespaces/openshift-kube-apiserver/pods

#kube-apiserver_check

#clear

cd $OUTPUT_PATH
#$OUTPUT_PATH/output_kube-apiserver_logs.log
cat $OUTPUT_PATH/output_keepalived_logs.log $OUTPUT_PATH/output_router_logs.log $OUTPUT_PATH/output_etcd_logs.log $OUTPUT_PATH/output_haproxy_logs.log > $OUTPUT_PATH/output_logs-$STAMP.log
sort -tT -k2 -k3 $OUTPUT_PATH/output_logs-$STAMP.log > $OUTPUT_PATH/sort.txt
sort -s -t- -k2 -k3 $OUTPUT_PATH/sort.txt > $OUTPUT_PATH/output_logs-$STAMP.log

cat $OUTPUT_PATH/output_logs-$STAMP.log