#!/bin/bash

MUST_PATH=$1
# PLOT=$2
STAMP=$(date +%Y-%m-%d_%H-%M-%S)
#REPORT_FOLDER="$HOME/ETCD-SUMMARY_$STAMP"
ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA
mkdir -p $OUTPUT_PATH

NODES=()
MASTER=()
INFRA=()
WORKER=()
OCS=()
ETCD=()

#mkdir -p $REPORT_FOLDER
#echo "created $REPORT_FOLDER"
echo -e ""

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


# MAIN --------------------------
cd $MUST_PATH
cd $(echo */)
# ls


# CLUSTER VERSION ---------------

[ -e "cluster-scoped-resources/config.openshift.io/clusterversions.yaml" ] && OCP_VERSION=$(cat cluster-scoped-resources/config.openshift.io/clusterversions.yaml |grep "Cluster version is"| grep -Po "(\d+\.)+\d+") || echo -e "no clusterversion.yaml found."
  
if [ -z "$OCP_VERSION" ]; then
  echo -e "Cluster version is EMPTY!"
  echo -e "IMPORTANT: cluster version file might be missing or corrupted due to ongoing upgrade (moving between versions)."
else
  echo -e "Cluster version is $OCP_VERSION"
fi

#supported version check
if [[ "$OCP_VERSION" == *"4.10"* || "$OCP_VERSION" == *"4.9"* ]];
  then
     echo -e "${RED}[WARNING] UNSUPPORTED OLD VERSION!!! ${NONE}"
  # else
  #   echo -e "   ${RED}[WARNING]${NONE} Found $OVERLOAD overloaded messages while there should be zero of them."
  fi
  echo -e ""


echo -e ""




# LIST NODES --------------------

cd cluster-scoped-resources/core/nodes
NODES_NUMBER=$(ls|wc -l)
echo -e "There are $NODES_NUMBER nodes in cluster"

# STORAGE

cd ../persistentvolumes
[ -d "../persistentvolumes" ] && PVCS=$(ls) && PV_NUMBER=$(ls|wc -l) && echo -e "There are $PV_NUMBER PVs in cluster" || echo -e "${RED}No PV files found. MISSING.${NONE}"

# echo "" > $OUTPUT_PATH/pvcs
# for i in $PVCS; do
#   echo $(cat $i |grep "storageClassName"|grep -v "f:storageClassName") >> $OUTPUT_PATH/pvcs
# done

# echo -e "Class:"
# cat $OUTPUT_PATH/pvcs |sort -u|uniq

# NODES
cd ../nodes
for filename in *.yaml; do
    [ -e "$filename" ] || continue
    [ ! -z "$(cat $filename |grep node-role|grep -w 'node-role.kubernetes.io/master:')" ] && MASTER+=("${filename::-5}") && NODES+=("$filename [master]") || true
done

for filename in *.yaml; do
    [ -e "$filename" ] || continue
    [ ! -z "$(cat $filename |grep node-role|grep -w 'node-role.kubernetes.io/infra:')" ] && INFRA+=("${filename::-5}")  && NODES+=("$filename [infra]") || true
done

for filename in *.yaml; do
    [ -e "$filename" ] || continue
    [ ! -z "$(cat $filename |grep node-role|grep -w 'node-role.kubernetes.io/worker:')" ] && WORKER+=("${filename::-5}")  && NODES+=("$filename [worker]") || true
done

for filename in *.yaml; do
    [ -e "$filename" ] || continue
    [ ! -z "$(cat $filename |grep -w 'cluster.ocs.openshift.io/openshift-storage')" ] && OCS+=("${filename::-5}")  || true
done

echo -e ""
echo -e "${GREEN}- NODES --------------------${NONE}"
echo -e ""
echo -e "${#MASTER[@]} masters"

# check if there's no more than supported number of masters (which is 3)
if (( ${#MASTER[@]} > 3 )); then
    echo -e "    ${RED}[WARNING] only 3 masters are supported, you have ${#MASTER[@]}.${NONE}"
fi

# check if any master is missing
if (( ${#MASTER[@]} < 3 )); then
    echo -e "    [WARNING] you have only ${#MASTER[@]} masters. Investigate SOSreport from missing one!"
fi

echo -e ""
echo -e "Minimum 4 vCPU (additional are strongly recommended)."
echo -e "Minimum 16 GB RAM (additional memory is strongly recommended, especially if etcd is co-located on masters)."
echo -e ""

for filename in *.yaml; do 
  [ -e "$filename" ] || continue
  [ ! -z "$(cat $filename |grep node-role|grep -w 'node-role.kubernetes.io/master:')" ] && echo -e "- $filename" && cat $filename |grep cpu|grep -v "f:cpu"|grep -v "m" || true
  [ ! -z "$(cat $filename |grep node-role|grep -w 'node-role.kubernetes.io/master:')" ] && cat $filename |grep memory|grep -v "f:memory"|grep -v 'message' || true
  [ ! -z "$(cat $filename |grep node-role|grep -w 'node-role.kubernetes.io/master:')" ] && cat $filename |grep type|| true
done
echo -e ""

echo -e "${#INFRA[@]} infra nodes"

# check for infra nodes and suggest consideration 
if (( ${#INFRA[@]} < 1 )); then
    echo -e "  ${RED}[WARNING]${NONE} no INFRA nodes or not properly tagged with node-role.kubernetes.io/infra=\"\"."
    echo -e "            Condsider adding infra nodes to offload masters."
fi

for filename in *.yaml; do
  [ -e "$filename" ] || continue
  [ ! -z "$(cat $filename |grep node-role|grep -w 'node-role.kubernetes.io/infra:')" ] && echo -e "- $filename" &&cat $filename |grep cpu|grep -v "f:cpu"|grep -v "m" || true
  [ ! -z "$(cat $filename |grep node-role|grep -w 'node-role.kubernetes.io/infra:')" ] && cat $filename |grep memory|grep -v "f:memory"|grep -v 'message' || true
done

echo -e ""
echo -e "${#WORKER[@]} workers"



echo -e ""

echo -e "${#OCS[@]} OCS storage nodes"

# check for infra nodes and suggest consideration 
# if (( ${#OCS[@]} < 1 )); then
#     echo -e "  ${RED}[WARNING]${NONE} no INFRA nodes or not properly tagged with node-role.kubernetes.io/infra=\"\"."
# fi

for filename in *.yaml; do
  [ -e "$filename" ] || continue
  [ ! -z "$(cat $filename |grep -w 'openshift-storage:')" ] && echo -e "- $filename" || true
  # [ ! -z "$(cat $filename |grep -w 'openshift-storage')" ] && echo -e "            " && cat $filename |grep memory|grep -v "f:memory"|grep -v 'message' || true
done




echo -e ""
echo -e "${GREEN}- NETWORKING --------------${NONE}"
echo -e ""

# Clusternetwork.yaml only exists for openshift-sdn
# OVN-K doesn't use it
# Better get it from the 'network'  object at either 'config.openshift.io' or 'operator.openshift.io'  api groups

#networkType

cd ../../config.openshift.io
cat networks.yaml|grep 'networkType' |uniq
cat networks.yaml|grep 'cidr' |uniq

# [ -d "../persistentvolumes" ] && PVCS=$(ls) && PV_NUMBER=$(ls|wc -l) && echo -e "There are $PV_NUMBER PVs in cluster" || echo -e "${RED}No PV files found. MISSING.${NONE}"

# [ -d "../persistentvolumes" ] && PVCS=$(ls) && PV_NUMBER=$(ls|wc -l) && echo -e "There are $PV_NUMBER PVs in cluster" || echo -e "${RED}No PV files found. MISSING.${NONE}"
# cd ../../../cluster-scoped-resources/network.openshift.io/clusternetworks/
# cat default.yaml |grep CIDR
# cat default.yaml |grep plugin
# cat default.yaml | grep serviceNetwork

echo -e ""
echo -e "${GREEN}- openshift-ingress router pods:${NONE}"
echo -e ""

cd $MUST_PATH
cd $(echo */)
cd namespaces/openshift-ingress/pods
for router in $(ls); do
  echo -e "" > $OUTPUT_PATH/$router.log
  WATCH=$(cat $router/router/router/logs/current.log |grep 'Unexpected watch close'|wc -l)
  RERR=$(cat $router/router/router/logs/current.log |grep 'error on the server'|wc -l)
  DEAD=$(cat $router/router/router/logs/current.log |grep 'context deadline exceeded'|wc -l)
  CLTIME=$(cat $router/router/router/logs/current.log |grep 'timeout'|wc -l)

  PRC=$(cat $router/router/router/logs/current.log |grep 'process'|wc -l)
  CLK=$(cat $router/router/router/logs/current.log |grep 'clock'|wc -l)
  BFR=$(cat $router/router/router/logs/current.log |grep 'buffer'|wc -l)
# cat $router/router/router/logs/current.log |grep 'process'
  echo -e ""
  echo "$router:"
  if [[ "$WATCH" -eq 0 ]];
  then
    echo -e "   no 'Unexpected watch close' message - ${GREEN}OK!${NONE}"
  else
    echo -e "   ${RED}[WARNING]${NONE} we found $WATCH 'Unexpected watch close' messages."
  fi
  if [[ "$RERR" -eq 0 ]];
  then
    echo -e "   no 'error on the server' message - ${GREEN}OK!${NONE}"
  else
    echo -e "   ${RED}[WARNING]${NONE} we found $RERR 'error on the server' messages."
  fi
    if [[ "$DEAD" -eq 0 ]];
  then
    echo -e "   no 'context deadline exceeded' message - ${GREEN}OK!${NONE}"
  else
    echo -e "   ${RED}[WARNING]${NONE} we found $DEAD 'context deadline exceeded' messages."
  fi
  if [[ "$CLTIME" -eq 0 ]];
  then
    echo -e "   no 'ClientTimeout' message - ${GREEN}OK!${NONE}"
  else
    echo -e "   ${RED}[WARNING]${NONE} we found $CLTIME 'ClientTimeout' messages."
  fi
  if [[ "$PRC" -eq 0 ]];
  then
    echo -e "   no 'Failed to open XYZ for getting process status' message - ${GREEN}OK!${NONE}"
  else
    echo -e "   ${RED}[WARNING]${NONE} we found $PRC 'Failed to open XYZ for getting process status' messages."
  fi
  if [[ "$CLK" -eq 0 ]];
  then
    echo -e "   no 'clock' message - ${GREEN}OK!${NONE}"
  else
    echo -e "   ${RED}[WARNING]${NONE} we found $CLK 'clock' messages."
  fi
  if [[ "$BFR" -eq 0 ]];
  then
    echo -e "   no 'buffer' message - ${GREEN}OK!${NONE}"
  else
    echo -e "   ${RED}[WARNING]${NONE} we found $BFR 'buffer' messages."
  fi
done

echo -e ""
echo -e "TIP: Additionaly check sosreports for dropped packets and RX/TX errors."
echo -e ""
echo -e ""

# omc get clusterversion
# omc get co | grep -v -e "True.*False.*False"
# omc get nodes | grep -v -e " Ready "
# omc get mcp | grep -v -e "True.*False.*False"
# omc get pods -A  -o wide | grep -v -e "Running" -e "Completed"
# omc get machinehealthcheck -n openshift-machine-api
# omc get csv -A | grep -v -e Succeeded
# omc get events -A | grep -v -e " Normal "
# for i in $(omc -n openshift-etcd get pods -l app=etcd -o name); do echo "-- $i"; omc -n openshift-etcd logs $i -c etcd 2>&1 | awk -v min=999 '/took too long/ {t++} /context deadline exceeded/ {b++} /finished scheduled compaction/ {gsub("\"",""); sub("ms}",""); split($0,a,":"); if (a[12]<min) min=a[12]; if (a[12]>max) max=a[12]; avg+=a[12]; c++} END{printf "took too long: %d\ndeadline exceeded: %d\n",t,b; printf "compaction times:\n  min: %d\n  max: %d\n  avg:%d\n",min,max,avg/c}'; done


# router_check() {  
#   echo -e ""
#   echo -e "[ROUTER openshift-ingress check]"
#   echo -e ""
#   [ -d "$ORIG_PATH/namespaces/openshift-ingress/pods" ] && echo "found directory" || return
#   i=0
#   cd $ORIG_PATH/namespaces/openshift-ingress/pods
#   for router in $(ls); do
#     echo "processing $router"
#     echo -e "" > $OUTPUT_PATH/$router.log
#     cat $router/router/router/logs/current.log |grep 'Unexpected watch close'|cut -d ' ' -f1| \
#       xargs -I {} echo -e "{} Unexpected watch close     [$router] !!!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$router.log; done
#     cat $router/router/router/logs/current.log |grep 'error on the server'|cut -d ' ' -f1| \
#       xargs -I {} echo -e "{} error on the server  [$router]" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$router.log; done
#     # cat $router/router/router/logs/current.log |grep 'process'|cut -d ' ' -f1| \
#     #   xargs -I {} echo -e "{} LEADER changed [$router] !" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$router.log; done
#     # cat $router/router/router/logs/current.log |grep 'clock'|cut -d ' ' -f1| \
#     #   xargs -I {} echo -e "{} NTP clock difference [$router] !!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$router.log; done
#     # cat $router/router/router/logs/current.log |grep 'buffer'|cut -d ' ' -f1| \
#     #   xargs -I {} echo -e "{} BUFF [$router] !!" | while read -r line; do echo -e "$line" >> $OUTPUT_PATH/$router.log; done
#     #increment color
#     i=$((${i}+1))
#   done
#   i=0
#   cat $OUTPUT_PATH/router*.log > $OUTPUT_PATH/output_router_logs.log
#   sort -t:  -k2 -k3 $OUTPUT_PATH/output_router_logs.log > $OUTPUT_PATH/sorted.tmp
#   cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_router_logs.log
# }

# ETCD ---------------------------


cd $MUST_PATH
cd $(echo */)

echo -e ""
echo -e "${GREEN}- ETCD --------------------${NONE}"
echo -e ""
cd namespaces/openshift-etcd/pods
for dirs in $(ls |grep -v guard|grep -v installer|grep -v quorum|grep -v pruner); do
    [ -e "$dirs" ] || continue
    [ ! -z "$(ls |grep -v guard|grep -v installer|grep -v quorum|grep -v pruner)" ] && ETCD+=("${dirs}") || true
    #echo -e "adding $dirs"
done
# check if there's no more than supported number of masters (which is 3)
if (( ${#ETCD[@]} > 3 )); then
    echo -e "    [WARNING] only 3 etcd members are supported, you have ${#ETCD[@]}."
fi

# check if any master is missing
if (( ${#ETCD[@]} < 3 )); then
    echo -e "    [WARNING] you have only ${#ETCD[@]} etcd members. Investigate logs from missing one!"
fi

# echo -e "${#ETCD[@]} etcd members"
for member in "${ETCD[@]}"; do
  echo -e "\n${GREEN}-[$member] ---${NONE}\n"
  # echo -e ""
  OVERLOAD=$(cat $member/etcd/etcd/logs/current.log|grep 'overload'|wc -l)
  OVERLOADN=$(cat $member/etcd/etcd/logs/current.log|grep 'overload'|grep network|wc -l)
  RAPOVERN=$(cat $member/etcd/etcd/logs/current.log|grep 'overload'|grep network |tail -n 1 |grep "remote-peer-active\":false")
  OVERLOADC=$(cat $member/etcd/etcd/logs/current.log|grep 'overload'|grep disk|wc -l)
  LAST=$(cat $member/etcd/etcd/logs/current.log|grep 'overload'|tail -1 |cut -d ':' -f1|cut -c 1-10)
  LOGEND=$(cat $member/etcd/etcd/logs/current.log|tail -1 |cut -d ':' -f1|cut -c 1-10)
  CLOCK=$(cat $member/etcd/etcd/logs/current.log|grep 'clock difference'|wc -l)
  LASTNTP=$(cat $member/etcd/etcd/logs/current.log|grep 'clock difference'|tail -1)
  LONGDRIFT=$(cat $member/etcd/etcd/logs/current.log|grep 'clock-drift'|wc -l)
  LASTLONGDRIFT=$(cat $member/etcd/etcd/logs/current.log|grep 'clock-drift'|tail -1)
  TOOK=$(cat $member/etcd/etcd/logs/current.log|grep 'apply request took too long'|wc -l)
  HEART=$(cat $member/etcd/etcd/logs/current.log|grep 'failed to send out heartbeat on time'|wc -l)
  SPACE=$(cat $member/etcd/etcd/logs/current.log|grep 'database space exceeded'|wc -l)
  LEADER=$(cat $member/etcd/etcd/logs/current.log|grep 'leader changed'|wc -l)

  OVRL=0
  NTP=0
  HR=0
  TK=0
  LED=0

  # overloaded
  if [[ "$OVERLOAD" -eq 0 ]];
  then
     echo -e "   no overloaded message - ${GREEN}OK!${NONE}"
  else
    echo -e "   ${RED}[WARNING]${NONE} Found $OVERLOAD overloaded messages while there should be zero of them."
    echo -e ""
    if [[ -n $RAPOVERN ]]; then
      echo -e "   - $OVERLOADN x OVERLOADED NETWORK in $member"
      echo -e "     (high network or remote storage latency, the peer is not responding, missing the availability to connect to another member)"
    else
      echo -e "   - $OVERLOADN x OVERLOADED NETWORK in $member"
      echo -e "     (high network or remote storage latency, the peer is responding, but too slow or only occasionally)"
    fi
    echo -e ""
    echo -e "   - $OVERLOADC x OVERLOADED DISK/CPU in $member  (slow storage or lack of CPU on masters)"
    echo -e ""
    if [ "$LAST" = "$LOGEND" ]; then
      echo -e "   Warnings last seen on $LAST. ${RED}TODAY!${NONE}"
    else
      echo -e "   Warnings last seen on $LAST. ${GREEN}NOT TODAY!${NONE}"
    fi
    echo -e "   Log ends on $LOGEND"
    echo -e ""
    echo -e "   SOLUTION: Review ETCD and CPU metrics as this could be caused by CPU bottleneck or slow disk (or combination of both)."
    echo -e ""
  fi
  
  # took too long
  if [ "$TOOK" != "0" ]; then
    echo -e "   ${RED}[WARNING]${NONE} we found $TOOK 'apply request took too long' messages. (You should be concerned only with several thousands of messages)"
    echo -e "   $SUMMARY"
    TK=$(($TK+$TOOK))
    echo -e ""
  else
    echo -e "   no 'apply request took too long' messages"
    echo -e ""
  fi


  # compaction

  echo -e "   [ETCD compaction]\n"
  echo -e "   To avoid running out of space for writes to the keyspace, the etcd keyspace history must be compacted. Storage space itself may be reclaimed by defragmenting etcd members."
  echo -e "   Compaction should be below 200ms on small cluster, below 500ms on medium cluster and below 800ms on large cluster."
  echo -e "   IMPORTANT: if compaction vary too much (and for example jumps from 100 to 600) it could mean masters are using shared storage or network storage with bad latency."
  echo -e ""
  cat $member/etcd/etcd/logs/current.log|grep compaction| tail -8 > $OUTPUT_PATH/$member-compat.data
  echo -e "   last compaction:\n"
  cat $OUTPUT_PATH/$member-compat.data| while read line 
  do
    CHECK=$(echo $line|tail -8|cut -d ':' -f12| rev | cut -c9- | rev|cut -c2- |grep -E '[0-9]')
    [[ ! -z "$(echo $CHECK |grep -E '[0-9]s')" ]] && echo -e "${RED}   $CHECK <---- TOO HIGH!${NONE}" || echo "   $CHECK"
  done
  echo -e ""

  # ntp
  if [ "$CLOCK" != "0" ]; then
    echo -e "${RED}[WARNING]${NONE} we found $CLOCK ntp clock difference messages in $1"
    NTP=$(($NTP+$CLOCK))
    echo -e "   Last occurrence:"
    echo -e "   $LASTNTP"| cut -d " " -f1
    echo -e "   Log ends at "
    echo -e "   $LOGENDNTP"| cut -d " " -f1
    echo -e ""
    echo -e "   Long drift: $LONGDRIFT"
    echo -e "   Last long drift:"
    echo -e "   $LASTLONGDRIFT"
        echo -e ""
    echo -e "   SOLUTION: When clocks are out of sync with each other they are causing I/O timeouts and the liveness probe is failing which makes the ETCD pod to restart frequently. Check if Chrony is enabled, running, and in sync with:"
    echo -e "          - chronyc sources"
    echo -e "          - chronyc tracking"
    echo -e ""
  else
    echo -e "   no NTP related warnings found - ${GREEN}OK!${NONE}"
  fi

  # heartbeat
  echo -e ""
  if [ "$HEART" != "0" ]; then
    echo -e "   ${RED}[WARNING]${NONE} we found $HEART failed to send out heartbeat on time messages. Usually this issue is caused by a slow disk."
    HR=$(($HR+$HEART))
  else
    echo -e "   no 'failed to send out heartbeat on time' messages found - ${GREEN}OK!${NONE}"
  fi

  # space
  echo -e ""
  if [ "$SPACE" != "0" ]; then
    echo -e "   ${RED}[WARNING]${NONE} we found $SPACE 'database space exceeded'"
    SP=$(($SP+$SPACE))
    echo -e ""
    echo -e "SOLUTION: Defragment and clean up ETCD, remove unused secrets or deployments."
    echo -e ""
  else
    echo -e "   no 'database space exceeded' messages found - ${GREEN}OK!${NONE}"
  fi

  # leader changes
  echo -e ""
  if [ "$LEADER" != "0" ]; then
    echo -e "   ${RED}[WARNING]${NONE} we found $LEADER 'leader changed'"
    LED=$(($LED+$LEADER))
  else
    echo -e "   no 'leader changed' messages found - ${GREEN}OK!${NONE}"
  fi
done


echo -e ""





echo -e ""
echo -e "[API CONSUMERS kube-apiserver on masters]"
echo -e ""
cd $MUST_PATH
cd $(echo */)
[ -d "audit_logs/kube-apiserver/" ]  && echo -e "Audit logs found. Processing." || echo -e "${RED}No audit logs found. MISSING.${NONE}" && exit 0
cd audit_logs/kube-apiserver/

AUDIT_LOGS=$(ls *.gz|grep audit)
node=""
for i in $AUDIT_LOGS; do
  #echo -e "[ extracting $i ]"
  gzip -d $i  
done;
AUDIT_LOGS=$(ls *.log)
for i in $AUDIT_LOGS; do
  echo -e "[ processing $i ]"
  if [[ $i == *".log"* ]]; then
    cat $i |jq '.user.username' -r > $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2)_2sort.log
    sort $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2)_2sort.log | uniq -c | sort -bgr| head -10
    echo -e ""
  else
    node=$i
    continue
  fi

done;




# etcd_took_too_long() {
#     TOOKS_MS=()
#     MS=$(cat $1/etcd/etcd/logs/current.log|grep 'apply request took too long'|tail -1)
#     echo $MS
#     TOOK=$(cat $1/etcd/etcd/logs/current.log|grep 'apply request took too long'|wc -l)
#     SUMMARY=$(cat $1/etcd/etcd/logs/current.log |awk -v min=999 '/apply request took too long/ {t++} /context deadline exceeded/ {b++} /finished scheduled compaction/ {gsub("\"",""); sub("ms}",""); split($0,a,":"); if (a[12]<min) min=a[12]; if (a[12]>max) max=a[12]; avg+=a[12]; c++} END{printf "took too long: %d\ndeadline exceeded: %d\n",t,b; printf "compaction times:\n  min: %d\n  max: %d\n  avg:%d\n",min,max,avg/c}'
# )
#     # if [ "$PLOT" = true ]; then
#     #   for lines in $(cat $1/etcd/etcd/logs/current.log||grep "apply request took too long"|grep -ohE "took\":\"[0-9]+(.[0-9]+)ms"|cut -c8-);
#     #   do
#     #     TOOKS_MS+=("$lines");
#     #     if [ "$lines" != "}" ]; then
#     #       echo $lines >> $REPORT_FOLDER/$1-long.data
#     #     fi
#     #   done
#     # fi
#     # if [ "$PLOT" = true ]; then
#     #   gnuplot_render $1 "${#TOOKS_MS[@]}" "took too long messages" "Sample number" "Took (ms)" "tooktoolong_graph" "$REPORT_FOLDER/$1-long.data"
#     # fi
#     if [ "$TOOK" != "0" ]; then
#       echo -e "${RED}[WARNING]${NONE} we found $TOOK 'apply request took too long' messages in $1"
#       echo -e "$SUMMARY"
#       TK=$(($TK+$TOOK))
#       echo -e ""
#     fi
# }



# help_etcd_objects() {
#   echo -e ""
#   echo -e "- Number of objects ---"
#   echo -e ""
#   echo -e "List number of objects in ETCD:"
#   echo -e ""
#   echo -e "$ oc project openshift-etcd"
#   echo -e "oc get pods"
#   echo -e "oc rsh etcd-ip-10-0-150-204.eu-central-1.compute.internal"
#   echo -e "> etcdctl get / --prefix --keys-only | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn"
#   echo -e ""
#   echo -e "[HINT] Any number of CRDs (secrets, deployments, etc..) above 8k could cause performance issues on storage with not enough IOPS."

#   echo -e ""
#   echo -e "List secrets per namespace:"
#   echo -e ""
#   echo -e "> oc get secrets -A --no-headers | awk '{ns[\$1]++}END{for (i in ns) print i,ns[i]}'"
#   echo -e ""
#   echo -e "[HINT] Any namespace with 20+ secrets should be cleaned up (unless there's specific customer need for so many secrets)."
#   echo -e ""
# }

# help_etcd_troubleshoot() {
#   echo -e ""
#   echo -e "- Generic troubleshooting ---"
#   echo -e ""
#   echo -e "More details about troubleshooting ETCD can be found at https://access.redhat.com/articles/6271341"
# }

# help_etcd_metrics() {
#   echo -e ""
#   echo -e "- ETCD metrics ---"
#   echo -e ""
#   echo -e "How to collect ETCD metrics. https://access.redhat.com/solutions/5489721"
# }

# help_etcd_networking() {
#   echo -e ""
#   echo -e "- ETCD networking troubleshooting ---"
#   echo -e ""
#   echo -e "From masters check if there are no dropped packets or RX/TX errors on main NIC."
#   echo -e "> ip -s link show"
#   echo -e ""
#   echo -e "but also check latency against API (expected value is 2-5ms, 0.002-0.005 in output)"
#   echo -e "> curl -k https://api.<OCP URL>.com -w \"%{time_connect}\""
#   echo -e "Any higher latency could mean network bottleneck."
# }

# help_etcd_objects


# etcd_ntp() {
#     CLOCK=$(cat $1/etcd/etcd/logs/current.log|grep 'clock difference'|wc -l)
#     LASTNTP=$(cat $1/etcd/etcd/logs/current.log|grep 'clock difference'|tail -1)
#     LONGDRIFT=$(cat $1/etcd/etcd/logs/current.log|grep 'clock-drift'|wc -l)
#     LASTLONGDRIFT=$(cat $1/etcd/etcd/logs/current.log|grep 'clock-drift'|tail -1)
#     LOGENDNTP=$(cat $1/etcd/etcd/logs/current.log|tail -1)
#     if [ "$CLOCK" != "0" ]; then
#       echo -e "${RED}[WARNING]${NONE} we found $CLOCK ntp clock difference messages in $1"
#       NTP=$(($NTP+$CLOCK))
#       echo -e "Last occurrence:"
#       echo -e "$LASTNTP"| cut -d " " -f1
#       echo -e "Log ends at "
#       echo -e "$LOGENDNTP"| cut -d " " -f1
#       echo -e ""
#       echo -e "Long drift: $LONGDRIFT"
#       echo -e "Last long drift:"
#       echo -e $LASTLONGDRIFT
#     fi
# }






#COMPATION

# echo -e ""
# echo -e "[COMPACTION]"
# echo -e "should be ideally below 100ms (and below 10ms on fast SSD/NVMe) on small clusters, 300-500 on medium or large and no more than 800-900ms on very large clusters."
# echo -e ""
# for member in "${ETCD[@]}"; do
#   etcd_compaction $member
# done


# MAIN FUNCS

overload_solution() {
    
}




audit_logs() {
  cd $MUST_PATH
  cd $(echo */)
  cd audit_logs/kube-apiserver/
  echo -e ""
  echo -e "[API CONSUMERS kube-apiserver on masters]"
  echo -e ""
  AUDIT_LOGS=$(ls *.gz|grep audit)
  node=""

  for i in $AUDIT_LOGS; do
    #echo -e "[ extracting $i ]"
    gzip -d $i  
  done;

  AUDIT_LOGS=$(ls *.log)
  for i in $AUDIT_LOGS; do
    echo -e "[ processing $i ]"
    if [[ $i == *".log"* ]]; then
      cat $i |jq '.user.username' -r > $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2)_2sort.log
      sort $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2)_2sort.log | uniq -c | sort -bgr| head -10
      echo -e ""
    else
      node=$i
      continue
    fi
  
  done;
}

# timed out waiting for read index response (local node might have slow network)





echo -e ""
echo -e "ADDITIONAL HELP:"
# help_etcd_troubleshoot
# help_etcd_metrics
# help_etcd_networking
# help_etcd_objects
