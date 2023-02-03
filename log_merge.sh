#!/bin/bash

################################################################################
#                     Must-gather log merger                                   #
#                                                                              #
# Script to merge logs from ETCD, apiserver, haproxy and routers               #
#                                                                              #
#                                                                              #
################################################################################
################################################################################
################################################################################
#                                                                              #
#  Copyright (C) 2022 Peter Ducai                                              #
#  peter.ducai@gmail.com                                                       #
#  pducai@icloud.com                                                           #
#                                                                              #
#  This program is free software; you can redistribute it and/or modify        #
#  it under the terms of the GNU General Public License as published by        #
#  the Free Software Foundation; either version 2 of the License, or           #
#  (at your option) any later version.                                         #
#                                                                              #
#  This program is distributed in the hope that it will be useful,             #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of              #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
#  GNU General Public License for more details.                                #
#                                                                              #
#  You should have received a copy of the GNU General Public License           #
#  along with this program; if not, write to the Free Software                 #
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA   #
#                                                                              #
################################################################################
################################################################################
################################################################################


STAMP=$(date +%Y-%m-%d_%H-%M-%S)
ETCD_NS="openshift-etcd"
MUST_PATH=""
ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA

#rm -rf $OUTPUT_PATH
mkdir -p $OUTPUT_PATH

print_help() {
  echo -e ""
  echo -e "Must-gather log merger 0.1"
  echo -e ""
  echo -e "WARNING: final output is simplified and you should check specific logs for exact error message and values."
  echo -e "For example:"
  echo -e "OVERLOADED = leader failed to send out heartbeat on time; took too long, leader is overloaded likely from slow disk"
  echo -e ""
  echo -e "Start at $STAMP"
  echo -e ""
  echo -e "SUMMARY: Script to merge logs from ETCD, apiserver, haproxy and routers"
  echo -e ""
  echo -e "HELP:"
  # echo -e "-f | --force : to actually delete ReplicaSets not in use. (Not implemented)"
  # echo -e "-g | --graph : graph referenced images. (Not implemented)"
  echo -e "-m | --mustgatherpath : path to must-gather folder."
  echo -e "-t | --timeline : print only specific timeline. Format can be YYYY-MM-DD or even YYYY-MM-DDTH (like 2022-10-13T02 for 02:00)."
  echo -e ""
}

# PARSER --------------------------------------------------------------------------

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -a|--my-boolean-flag)
      MY_FLAG=0
      shift
      ;;
    -t|--timeline)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        TIMELINE=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -m|--mustgatherpath)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        MUST_PATH=$2
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

print_help


for log in $(cat merge_list.txt); do
    echo "processing $log"
    #  xargs -I {} echo -e "{} failed to send out heartbeat on time; took too long, leader is overloaded likely from slow disk     [$member] !!!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$member.log; done
    # cat $member/etcd/etcd/logs/current.log |grep 'took too long'|cut -d ' ' -f1| \
      # xargs -I {} echo -e "{} took too long  [$member]" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$member.log; done
  done







# MAIN

FULL_PATH=$(pwd)


etcd_check() {
  echo -e ""
  echo -e "[ETCD check]"
  echo -e ""
  [ -d "$FULL_PATH/namespaces/$ETCD_NS/pods" ] && echo "found directory" || return
  cd $FULL_PATH/namespaces/$ETCD_NS/pods
  i=0
  
  for member in $(ls |grep -v "revision"|grep -v "quorum"); do
    echo "processing $member"
    echo -e "" > $OUTPUT_PATH/$member.log
    cat $member/etcd/etcd/logs/current.log |grep 'likely'|cut -d ' ' -f1| \
      xargs -I {} echo -e "{} failed to send out heartbeat on time; took too long, leader is overloaded likely from slow disk     [$member] !!!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$member.log; done
    # cat $member/etcd/etcd/logs/current.log |grep 'took too long'|cut -d ' ' -f1| \
      # xargs -I {} echo -e "{} took too long  [$member]" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$member.log; done
    cat $member/etcd/etcd/logs/current.log |grep 'leader changed'|cut -d ' ' -f1| \
      xargs -I {} echo -e "{} took too long due to changed leader [$member] !" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$member.log; done
    cat $member/etcd/etcd/logs/current.log |grep 'elected leader'|cut -d ' ' -f1| \
      xargs -I {} echo -e "{} LEADER changed [$member] !!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$member.log; done
    cat $member/etcd/etcd/logs/current.log |grep 'clock'|cut -d ' ' -f1| \
      xargs -I {} echo -e "{} NTP clock difference [$member] !!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$member.log; done
    cat $member/etcd/etcd/logs/current.log |grep 'buffer'|cut -d ' ' -f1| \
      xargs -I {} echo -e "{} dropped internal Raft message since sending buffer is full (overloaded network) [$member] !!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$member.log; done
    #increment color
    i=$((${i}+1))
  done
  i=0
  cat $OUTPUT_PATH/etcd*.log > $OUTPUT_PATH/output_etcd_logs.log
  sort -t:  -k2 -k3 $OUTPUT_PATH/output_etcd_logs.log > $OUTPUT_PATH/sorted.tmp
  cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_etcd_logs.log
}

router_check() {  
  echo -e ""
  echo -e "[ROUTER openshift-ingress check]"
  echo -e ""
  [ -d "$FULL_PATH/namespaces/openshift-ingress/pods" ] && echo "found directory" || return
  i=0
  cd $FULL_PATH/namespaces/openshift-ingress/pods
  for router in $(ls); do
    echo "processing $router"
    echo -e "" > $OUTPUT_PATH/$router.log
    cat $router/router/router/logs/current.log |grep 'Unexpected watch close'|cut -d ' ' -f1| \
      xargs -I {} echo -e "{} Unexpected watch close     [$router] !!!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$router.log; done
    cat $router/router/router/logs/current.log |grep 'error on the server'|cut -d ' ' -f1| \
      xargs -I {} echo -e "{} error on the server  [$router]" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$router.log; done
    # cat $router/router/router/logs/current.log |grep 'process'|cut -d ' ' -f1| \
    #   xargs -I {} echo -e "{} LEADER changed [$router] !" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$router.log; done
    # cat $router/router/router/logs/current.log |grep 'clock'|cut -d ' ' -f1| \
    #   xargs -I {} echo -e "{} NTP clock difference [$router] !!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$router.log; done
    # cat $router/router/router/logs/current.log |grep 'buffer'|cut -d ' ' -f1| \
    #   xargs -I {} echo -e "{} BUFF [$router] !!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$router.log; done
    #increment color
    i=$((${i}+1))
  done
  i=0
  cat $OUTPUT_PATH/router*.log > $OUTPUT_PATH/output_router_logs.log
  sort -t:  -k2 -k3 $OUTPUT_PATH/output_router_logs.log > $OUTPUT_PATH/sorted.tmp
  cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_router_logs.log
}

stackinfra_check() {
  echo -e ""
  echo -e "[KEEPALIVED openstack-infra check]"
  echo -e ""
  i=0
  [ -d "$FULL_PATH/namespaces/openshift-openstack-infra/pods" ] && echo "found directory" || return
  cd $FULL_PATH/namespaces/openshift-openstack-infra/pods
  for keepalived in $(ls |grep master|grep -v "coredns"|grep -v "haproxy"); do
    echo "processing $keepalived"
    echo -e "" > $OUTPUT_PATH/$keepalived.log
    cat $keepalived/keepalived/keepalived/logs/current.log |grep 'Entering'| \
      xargs -I {} echo -e "{}      [$keepalived] !!!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$keepalived.log; done
    #increment color
    i=$((${i}+1))
  done
  i=0
  cat $OUTPUT_PATH/keepalived*.log > $OUTPUT_PATH/output_keepalived_logs.log
  sort -t:  -k2 -k3 $OUTPUT_PATH/output_keepalived_logs.log > $OUTPUT_PATH/sorted.tmp
  cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_keepalived_logs.log
}

kube-apiserver_check() {
  echo -e ""
  echo -e "[KUBE-APISERVER check]"
  echo -e ""
  [ -d "$FULL_PATH/namespaces/openshift-kube-apiserver/pods" ] && echo "found directory" || return
  i=0
  cd $FULL_PATH/namespaces/openshift-kube-apiserver/pods
  for kubeapiserver in $(ls |grep -v "installer"|grep -v "pruner"|grep -v "guard"|grep apiserver); do
    echo "processing $kubeapiserver"
    echo -e "" > $OUTPUT_PATH/$kubeapiserver.log
    cat $kubeapiserver/kube-apiserver/kube-apiserver/logs/current.log |grep -i 'error'| \
      xargs -I {} echo -e "{}      [$kubeapiserver] !!!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$kubeapiserver.log; done
    #increment color
    i=$((${i}+1))
  done
  i=0
  cat $OUTPUT_PATH/kube-apiserver*.log > $OUTPUT_PATH/output_kube-apiserver_logs.log
  sort -t:  -k2 -k3 $OUTPUT_PATH/output_kube-apiserver_logs.log > $OUTPUT_PATH/sorted.tmp
  cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_kube-apiserver_logs.log
}

haproxy_check() {
  echo -e ""
  echo -e "[HAPROXY check]"
  echo -e ""
  [ -d "$FULL_PATH/namespaces/openshift-openstack-infra/pods" ] && echo "found directory" || return
  i=0
  cd $FULL_PATH/namespaces/openshift-openstack-infra/pods
  for haproxy in $(ls |grep haproxy|grep -v "coredns"|grep -v "kube-apiserver"); do
    echo "processing $haproxy"
    echo -e "" > $OUTPUT_PATH/$haproxy.log
    cat $haproxy/haproxy/haproxy/logs/current.log |grep -i 'error'| \
      xargs -I {} echo -e "{}      [$haproxy] !!!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$haproxy.log; done
    #increment color
    i=$((${i}+1))
  done
  i=0
  cat $OUTPUT_PATH/kube-apiserver*.log > $OUTPUT_PATH/output_haproxy_logs.log
  sort -t:  -k2 -k3 $OUTPUT_PATH/output_haproxy_logs.log > $OUTPUT_PATH/sorted.tmp
  cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_haproxy_logs.log
}


# etcd_check
# router_check
# stackinfra_check
# haproxy_check
# kube-apiserver_check

# #clear


# echo -e ""
# echo -e "[PROCESSING]"
# echo -e ""
# cd $OUTPUT_PATH
# #$OUTPUT_PATH/output_kube-apiserver_logs.log
# cat $OUTPUT_PATH/output_keepalived_logs.log $OUTPUT_PATH/output_router_logs.log $OUTPUT_PATH/output_etcd_logs.log $OUTPUT_PATH/output_haproxy_logs.log > $OUTPUT_PATH/output_logs-$STAMP.log
# sort -tT -k2 -k3 $OUTPUT_PATH/output_logs-$STAMP.log > $OUTPUT_PATH/sort.txt
# sort -s -t- -k2 -k3 $OUTPUT_PATH/sort.txt > $OUTPUT_PATH/output_logs-$STAMP.log

# #cat $OUTPUT_PATH/output_logs-$STAMP.log |grep "$TIMELINE"
# echo -e "Combined output was saved in $OUTPUT_PATH/output_logs-$STAMP.log"