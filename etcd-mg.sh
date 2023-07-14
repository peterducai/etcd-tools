#!/bin/bash

MUST_PATH=$1
PLOT=$2
STAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FOLDER="$HOME/ETCD-SUMMARY_$STAMP"
ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA

mkdir -p $REPORT_FOLDER
echo "created $REPORT_FOLDER"

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

cd $MUST_PATH
cd $(echo */)
# ls

if [ -z "$3" ]; then
  OCP_VERSION=$(cat cluster-scoped-resources/config.openshift.io/clusterversions.yaml |grep "Cluster version is"| grep -Po "(\d+\.)+\d+")
else
  OCP_VERSION=$3
fi

if [ -z "$OCP_VERSION" ]; then
  echo -e "Cluster version is EMPTY! Script cannot be run without defining proper version!"
  echo -e "Run script with: ./etcd.sh <path to must-gather> false 4.10     # for 4.10 or replace with your version"
else
  echo -e "Cluster version is $OCP_VERSION"
fi
echo -e ""

cd cluster-scoped-resources/core/nodes
NODES_NUMBER=$(ls|wc -l)
echo -e "There are $NODES_NUMBER nodes in cluster"

cd ../persistentvolumes
PV_NUMBER=$(ls|wc -l)
echo -e "There are $PV_NUMBER PVs in cluster"

cd ../nodes

NODES=()
MASTER=()
INFRA=()
WORKER=()

help_etcd_objects() {
  echo -e ""
  echo -e "- Number of objects ---"
  echo -e ""
  echo -e "List number of objects in ETCD:"
  echo -e ""
  echo -e "$ oc project openshift-etcd"
  echo -e "oc get pods"
  echo -e "oc rsh etcd-ip-10-0-150-204.eu-central-1.compute.internal"
  echo -e "> etcdctl get / --prefix --keys-only | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn"
  echo -e ""
  echo -e "[HINT] Any number of CRDs (secrets, deployments, etc..) above 8k could cause performance issues on storage with not enough IOPS."

  echo -e ""
  echo -e "List secrets per namespace:"
  echo -e ""
  echo -e "> oc get secrets -A --no-headers | awk '{ns[\$1]++}END{for (i in ns) print i,ns[i]}'"
  echo -e ""
  echo -e "[HINT] Any namespace with 20+ secrets should be cleaned up (unless there's specific customer need for so many secrets)."
  echo -e ""
}

help_etcd_troubleshoot() {
  echo -e ""
  echo -e "- Generic troubleshooting ---"
  echo -e ""
  echo -e "More details about troubleshooting ETCD can be found at https://access.redhat.com/articles/6271341"
}

help_etcd_metrics() {
  echo -e ""
  echo -e "- ETCD metrics ---"
  echo -e ""
  echo -e "How to collect ETCD metrics. https://access.redhat.com/solutions/5489721"
}

help_etcd_networking() {
  echo -e ""
  echo -e "- ETCD networking troubleshooting ---"
  echo -e ""
  echo -e "From masters check if there are no dropped packets or RX/TX errors on main NIC."
  echo -e "> ip -s link show"
  echo -e ""
  echo -e "but also check latency against API (expected value is 2-5ms, 0.002-0.005 in output)"
  echo -e "> curl -k https://api.<OCP URL>.com -w \"%{time_connect}\""
  echo -e "Any higher latency could mean network bottleneck."
}

# help_etcd_objects


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

echo -e ""
# echo ${NODES[@]}

echo -e "${#MASTER[@]} masters"
if [ "${#MASTER[@]}" != "3" ]; then
  echo -e "[WARNING] only 3 masters are supported, you have ${#MASTER[@]}."
fi
printf "%s\n" "${MASTER[@]}"
echo -e ""
echo -e "${#INFRA[@]} infra nodes"
printf "%s\n" "${INFRA[@]}"
echo -e ""
echo -e "${#WORKER[@]} worker nodes"
printf "%s\n" "${WORKER[@]}"

# for i in ${NODES[@]}; do echo $i; done


cd $MUST_PATH
cd $(echo */)
cd namespaces/openshift-etcd/pods
echo -e ""
echo -e "[ETCD]"

OVRL=0
NTP=0
HR=0
TK=0
LED=0


gnuplot_render() {
      cat > $REPORT_FOLDER/etcd-$1.plg <<- EOM
#! /usr/bin/gnuplot

set terminal png
set title '$3'
set xlabel '$4'
set ylabel '$5'

set autoscale
set xrange [1:$2]
set yrange [1:800]

# labels
#set label "- GOOD" at 0, 100
#set label "- BAD" at 0, 300
#set label "- SUPER BAD" at 0, 500

plot '$7' with lines
EOM

    gnuplot  $REPORT_FOLDER/etcd-$1.plg > $REPORT_FOLDER/$1$6.png
}

etcd_overload() {
  echo -e ""
  OVERLOAD=$(cat $1/etcd/etcd/logs/current.log|grep 'overload'|wc -l)
  OVERLOADN=$(cat $1/etcd/etcd/logs/current.log|grep 'overload'|grep network|wc -l)
  OVERLOADC=$(cat $1/etcd/etcd/logs/current.log|grep 'overload'|grep disk|wc -l)
  LAST=$(cat $1/etcd/etcd/logs/current.log|grep 'overload'|tail -1 |cut -d ':' -f1|cut -c 1-10)
  LOGEND=$(cat $1/etcd/etcd/logs/current.log|tail -1 |cut -d ':' -f1|cut -c 1-10)
  echo -e "$1"
  if [[ "$OVERLOAD" -eq 0 ]];
  then
     echo "no overloaded message - EXCELLENT!"
  else
    echo -e "Found $OVERLOAD overloaded messages while there should be zero of them.. last seen on $LAST"
    echo -e "details:"
    echo -e "$OVERLOADN x OVERLOADED NETWORK in $1  (high network or remote storage latency)"
    echo -e "$OVERLOADC x OVERLOADED DISK/CPU in $1  (slow storage or lack of CPU on masters)"
    echo -e "Log ends on $LOGEND"
  fi
  echo -e ""
}


etcd_took_too_long() {
    TOOKS_MS=()
    MS=$(cat $1/etcd/etcd/logs/current.log|grep 'apply request took too long'|tail -1)
    echo $MS
    TOOK=$(cat $1/etcd/etcd/logs/current.log|grep 'apply request took too long'|wc -l)
    SUMMARY=$(cat $1/etcd/etcd/logs/current.log |awk -v min=999 '/apply request took too long/ {t++} /context deadline exceeded/ {b++} /finished scheduled compaction/ {gsub("\"",""); sub("ms}",""); split($0,a,":"); if (a[12]<min) min=a[12]; if (a[12]>max) max=a[12]; avg+=a[12]; c++} END{printf "took too long: %d\ndeadline exceeded: %d\n",t,b; printf "compaction times:\n  min: %d\n  max: %d\n  avg:%d\n",min,max,avg/c}'
)
    if [ "$PLOT" = true ]; then
      for lines in $(cat $1/etcd/etcd/logs/current.log||grep "apply request took too long"|grep -ohE "took\":\"[0-9]+(.[0-9]+)ms"|cut -c8-);
      do
        TOOKS_MS+=("$lines");
        if [ "$lines" != "}" ]; then
          echo $lines >> $REPORT_FOLDER/$1-long.data
        fi
      done
    fi
    if [ "$PLOT" = true ]; then
      gnuplot_render $1 "${#TOOKS_MS[@]}" "took too long messages" "Sample number" "Took (ms)" "tooktoolong_graph" "$REPORT_FOLDER/$1-long.data"
    fi
    if [ "$TOOK" != "0" ]; then
      echo -e "${RED}[WARNING]${NONE} we found $TOOK 'apply request took too long' messages in $1"
      echo -e "$SUMMARY"
      TK=$(($TK+$TOOK))
      echo -e ""
    fi
}

etcd_ntp() {
    CLOCK=$(cat $1/etcd/etcd/logs/current.log|grep 'clock difference'|wc -l)
    LASTNTP=$(cat $1/etcd/etcd/logs/current.log|grep 'clock difference'|tail -1)
    LONGDRIFT=$(cat $1/etcd/etcd/logs/current.log|grep 'clock-drift'|wc -l)
    LASTLONGDRIFT=$(cat $1/etcd/etcd/logs/current.log|grep 'clock-drift'|tail -1)
    LOGENDNTP=$(cat $1/etcd/etcd/logs/current.log|tail -1)
    if [ "$CLOCK" != "0" ]; then
      echo -e "${RED}[WARNING]${NONE} we found $CLOCK ntp clock difference messages in $1"
      NTP=$(($NTP+$CLOCK))
      echo -e "Last occurrence:"
      echo -e "$LASTNTP"| cut -d " " -f1
      echo -e "Log ends at "
      echo -e "$LOGENDNTP"| cut -d " " -f1
      echo -e ""
      echo -e "Long drift: $LONGDRIFT"
      echo -e "Last long drift:"
      echo -e $LASTLONGDRIFT
    fi
}

etcd_heart() {
    HEART=$(cat $1/etcd/etcd/logs/current.log|grep 'failed to send out heartbeat on time'|wc -l)
    if [ "$HEART" != "0" ]; then
      echo -e "${RED}[WARNING]${NONE} we found $HEART failed to send out heartbeat on time messages in $1"
      HR=$(($HR+$HEART))
    fi
}

etcd_space() {
    SPACE=$(cat $member/etcd/etcd/logs/current.log|grep 'database space exceeded'|wc -l)
    if [ "$SPACE" != "0" ]; then
      echo -e "${RED}[WARNING]${NONE} we found $SPACE 'database space exceeded' in $1"
      SP=$(($SP+$SPACE))
    fi
}

etcd_leader() {
  LEADER=$(cat $member/etcd/etcd/logs/current.log|grep 'leader changed'|wc -l)
      if [ "$LEADER" != "0" ]; then
      echo -e "${RED}[WARNING]${NONE} we found $LEADER 'leader changed' in $1"
      LED=$(($LED+$LEADER))
    fi
}



etcd_compaction() {

  echo -e "etcd compaction on $1"
  # echo -e ""
  case "${OCP_VERSION}" in
  4.9*|4.8*|4.1*)
    #echo "# compaction" > $OUTPUT_PATH/$1.data
    cat $1/etcd/etcd/logs/current.log|grep compaction| tail -20 > $OUTPUT_PATH/$1-compat.data
    
    cat $OUTPUT_PATH/$1-compat.data| while read line 
    do
      # echo $line|tail -12|cut -d ':' -f12| rev | cut -c9- | rev|cut -c2- |grep -E '[0-9]'
      # echo $line|tail -12|cut -d ':' -f10| rev | cut -c9- | rev|cut -c2- |grep -E '[0-9]'
      # echo $line|tail -12|cut -d ':' -f10| rev | cut -c9- | rev|cut -c2- |grep -E '[0-9]'
      CHECK=$(echo $line|tail -12|cut -d ':' -f12| rev | cut -c9- | rev|cut -c2- |grep -E '[0-9]')
      [[ ! -z "$(echo $CHECK |grep -E '[0-9]s')" ]] && echo "$CHECK <---- TOO HIGH!" || echo $CHECK
    done
    ;;
  *)
    echo -e "unknown version ${OCP_VERSION} !"
    ;;
  esac
  echo -e ""
}



# MAIN FUNCS

overload_solution() {
    echo -e "SOLUTION: Review ETCD and CPU metrics as this could be caused by CPU bottleneck or slow disk."
    echo -e ""
}


overload_check() {
    echo -e ""
    echo -e "[OVERLOADED MESSAGES]"
    echo -e ""
    for member in $(ls |grep -v "revision"|grep -v "quorum"|grep -v "guard"); do
      etcd_overload $member
    done
    # echo -e "Found together $OVRL 'server is likely overloaded' messages."
    # echo -e ""
    # if [[ $OVRL -ne "0" ]];then
    #     overload_solution
    # fi
}

tooklong_solution() {
    echo -e ""
    echo -e "SOLUTION: Even with a slow mechanical disk or a virtualized network disk, applying a request should normally take fewer than 50 milliseconds (and around 5ms for fast SSD/NVMe disk)."
    echo -e ""
}

tooklong_check() {
    echo -e ""
    echo -e "[TOOK TOO LONG MESSAGES]"
    echo -e ""
    for member in $(ls |grep -v "revision"|grep -v "quorum"|grep -v "guard"); do
      etcd_took_too_long $member
    done
    echo -e ""
    if [[ $TK -eq "0" ]];then
        echo -e "Found zero 'took too long' messages.  OK"
    else
        echo -e "Found together $TK 'took too long' messages."
    fi
    if [[ $TK -ne "0" ]];then
        tooklong_solution
    fi
}



ntp_solution() {
    echo -e ""
    echo -e "SOLUTION: When clocks are out of sync with each other they are causing I/O timeouts and the liveness probe is failing which makes the ETCD pod to restart frequently. Check if Chrony is enabled, running, and in sync with:"
    echo -e "          - chronyc sources"
    echo -e "          - chronyc tracking"
    echo -e ""
}

ntp_check() {
    echo -e "[NTP MESSAGES]"
    for member in $(ls |grep -v "revision"|grep -v "quorum"|grep -v "guard"); do
      etcd_ntp $member
    done
    echo -e ""
    if [[ $NTP -eq "0" ]];then
        echo -e "Found zero NTP out of sync messages.  OK"
    else
        echo -e "Found together $NTP NTP out of sync messages."
    fi
    echo -e ""
    if [[ $NTP -ne "0" ]];then
        ntp_solution
    fi
}

heart_solution() {
    echo -e ""
    echo -e "SOLUTION: Usually this issue is caused by a slow disk. The disk could be experiencing contention among ETCD and other applications, or the disk is too simply slow."
    echo -e ""
}

heart_check() {
    # echo -e ""
    for member in $(ls |grep -v "revision"|grep -v "quorum"|grep -v "guard"); do
      etcd_heart $member
    done
    echo -e ""    
    if [[ $HEART -eq "0" ]];then
        echo -e "Found zero 'failed to send out heartbeat on time' messages.  OK"
    else
        echo -e "Found together $HR 'failed to send out heartbeat on time' messages."
    fi
    echo -e ""
    if [[ $HEART -ne "0" ]];then
        heart_solution
    fi
}

space_solution() {
    echo -e ""
    echo -e "SOLUTION: Defragment and clean up ETCD, remove unused secrets or deployments."
    echo -e ""
}

space_check() {
    echo -e "[SPACE EXCEEDED MESSAGES]"
    for member in $(ls |grep -v "revision"|grep -v "quorum"|grep -v "guard"); do
      etcd_space $member
    done
    echo -e ""
    if [[ $SP -eq "0" ]];then
        echo -e "Found zero 'database space exceeded' messages.  OK"
    else
        echo -e "Found together $SP 'database space exceeded' messages."
    fi
    echo -e ""
    if [[ $SPACE -ne "0" ]];then
        space_solution
    fi
}


leader_solution() {
    echo -e ""
    echo -e "SOLUTION: Defragment and clean up ETCD. Also consider faster storage."
    echo -e ""
}

leader_check() {
    echo -e "[LEADER CHANGED MESSAGES]"
    for member in $(ls |grep -v "revision"|grep -v "quorum"|grep -v "guard"); do
      etcd_leader $member
    done
    echo -e ""
    if [[ $LED -eq "0" ]];then
        echo -e "Found zero 'leader changed' messages.  OK"
    else
        echo -e "Found together $LED 'leader changed' messages."
    fi
    if [[ $LED -ne "0" ]];then
        leader_solution
    fi
}

compaction_check() {
  echo -e ""
  echo -e "[COMPACTION]"
  echo -e "should be ideally below 100ms (and below 10ms on fast SSD/NVMe) on small clusters, 300-500 on medium or large and no more than 800-900ms on very large clusters."
  echo -e ""
  for member in $(ls |grep -v "revision"|grep -v "quorum"|grep -v "guard"); do
    etcd_compaction $member
  done
  echo -e ""
  # echo -e "  Found together $LED 'leader changed' messages."
  # if [[ $LED -ne "0" ]];then
  #     leader_solution
  # fi
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

compaction_check
overload_check
tooklong_check
ntp_check
# heart_check
space_check
leader_check
audit_logs


echo -e ""
echo -e "[NETWORKING]"
cd ../../../cluster-scoped-resources/network.openshift.io/clusternetworks/
cat default.yaml |grep CIDR
cat default.yaml | grep serviceNetwork

echo -e ""
echo -e "ADDITIONAL HELP:"
help_etcd_troubleshoot
help_etcd_metrics
help_etcd_networking
help_etcd_objects