#!/bin/bash

################################################################################
#                               ETCD Analyzer                                  #
#                                                                              #
# Script to analyze performance of ETCD on live cluster                        #
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
CLIENT="oc"
ETCDNS='openshift-etcd'
MUST_PATH=$1
ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA

rm -rf $OUTPUT_PATH
mkdir -p $OUTPUT_PATH

# PARSER --------------------------------------------------------------------------

print_help() {
  echo -e "HELP:"
  echo -e "-k | --kubectl : use kubectl instead of oc (experimental)"
  echo -e "-h | --help : print this help"
  echo -e ""
}

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -k|--kubectl)
      CLIENT="kubectl"
      ETCDNS="kube-system"
      shift
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      print_help
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



MASTERS=$($CLIENT get nodes |grep master|cut -d ' ' -f1)
ETCD=( $($CLIENT --as system:admin -n $ETCDNS get -l k8s-app=etcd pods -o name | tr -s '\n' ' ' | sed 's/pod\///g' ) )
#API=$( oc config view --minify -o jsonpath='{.clusters[*].cluster.server}' )
API=$( $CLIENT get cm console-config -n openshift-console -o jsonpath="{.data.console-config\.yaml}" | grep masterPublicURL | awk '{print $2}' )
echo -e "API URL: $API"
TOKEN=$(oc whoami -t)




analyze_members() {
  for i in ${ETCD[@]}; do
    echo -e ""
    echo -e "-[$i]--------------------"
    
    echo -e ""
    $CLIENT exec -n $ETCDNS $i -c etcdctl -- etcdctl endpoint status -w table
    echo -e "IPs:"
    for j in $($CLIENT exec $i -c etcd -n $ETCDNS -- ls /sys/class/net|grep -v veth|grep -v lo); do echo $j && oc exec -n $ETCDNS $i -c etcd -- ip a s|grep inet|grep -v inet6|grep -v '127.'|head -2; done
    echo -e "Errors and dropped packets:"
    for j in $($CLIENT exec $i -c etcd -n $ETCDNS -- ls /sys/class/net|grep -v veth|grep -v lo); do oc exec -n $ETCDNS $i -c etcd -- ip -s link show dev $j; done
    echo -e ""
#    echo -e "Latency against API is $(curl -sk $API -w "%{time_connect}\n"|tail -1) .  Should be close to 0.002 (2ms) and no more than 0.008 (8ms)."
    echo -e "Latency against API is $(curl -sk -H "Authorization: Bearer $TOKEN" -X GET $API -w "%{time_connect}\n" --output /dev/null) .  Should be close to 0.002 (2ms) and no more than 0.008 (8ms)."
    echo -e ""
    echo -e ""
    echo -e "LOGS \nstart on $($CLIENT logs $i -c etcd -n $ETCDNS|head -60|tail -1|cut -d ':' -f3|cut -c 2-14)"
    echo -e "ends on $($CLIENT logs $i -c etcd -n $ETCDNS|tail -1|cut -d ':' -f3|cut -c 2-14)"
    echo -e ""
    echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep overloaded|wc -l) overloaded messages"
    echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep 'took too long'|wc -l) took too long messages"
    echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep 'slow fdatasync'|wc -l) slow fdatasync messages"
    echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep clock|wc -l) clock difference messages"
    echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep heartbeat|wc -l) heartbeat messages"
    echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep 'database space exceeded'|wc -l) database space exceeded messages"
    echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep 'leader changed'|wc -l) took too long due to leader changed messages"
    echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep 'elected leader'|wc -l) leader changed messages"
    echo -e ""
    echo -e "COMPACTION: \n$($CLIENT logs $i -c etcd -n $ETCDNS|grep compaction|tail -8|cut -d ':' -f10|cut -c 2-12)"
    echo -e ""
    echo -e "---------------------"
    echo -e ""
  done
  
}


analyze_members





echo -e ""
echo -e "[NUMBER OF OBJECTS IN ETCD]"
echo -e ""
$CLIENT exec -n $ETCDNS $i -c etcdctl -n $ETCDNS -- etcdctl get / --prefix --keys-only | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn|head -14
echo -e ""

echo -e "[MOST EVENTS keys]"
echo -e ""
$CLIENT exec -n $ETCDNS $i -c etcdctl -n $ETCDNS -- etcdctl get / --prefix --keys-only > keysonly.txt
cat keysonly.txt|grep event  |cut -d/ -f3,4| sort | uniq -c | sort -n --rev| head -10
echo -e "..."
#cat keysonly.txt | grep event |cut -d/ -f3,4,5| sort | uniq -c | sort -n --rev |head -10

# oc exec $i  -c etcdctl -n $ETCDNS --  etcdctl watch / --prefix  --write-out=fields > fields.txt

if [ $CLIENT == "kubectl" ]; then
  return
fi

echo -e ""
echo -e "[API CONSUMERS kube-apiserver on masters]"
echo -e ""
AUDIT_LOGS=$(oc adm node-logs --role=master --path=kube-apiserver|grep audit-)
node=""
for i in $AUDIT_LOGS; do
  echo -e "[ processing $i ]"
  if [[ $i == *".log"* ]]; then
    oc adm node-logs $node --path=kube-apiserver/$i > $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2)
    cat $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2) |jq '.user.username' -r > $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2).username
    sort $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2).username | uniq -c | sort -bgr|head -5
    echo -e ""
  else
    node=$i
    continue
  fi

done;



echo -e ""
echo -e "-------------------------------------------------------------------------------"
echo -e ""
echo -e ""
echo -e "[API CONSUMERS openshift-apiserver on masters]"
echo -e ""
AUDIT_LOGS=$(oc adm node-logs --role=master --path=openshift-apiserver|grep audit-)
node=""
for i in $AUDIT_LOGS; do
  echo -e "[ processing $i ]"
  if [[ $i == *".log"* ]]; then
    oc adm node-logs $node --path=openshift-apiserver/$i > $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2)
    cat $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2) |jq '.user.username' -r > $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2).username
    sort $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2).username | uniq -c | sort -bgr |head -5
    echo -e ""
  else
    node=$i
    continue
  fi

done;



















#   $ oc debug node/<master_node>
#   [...]
#   sh-4.4# chroot /host bash
#   podman run --privileged --volume /var/lib/etcd:/test quay.io/peterducai/$ETCDNS-suite:latest fio


    # $ oc debug node/<master_node>
    # [...]
    # sh-4.4# chroot /host bash
    # [root@<master_node> /]# podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf

# $CLIENT exec $i  -c etcdctl -n $ETCD_NS --  etcdctl watch / --prefix  --write-out=fields > fields.txt













#   $ $CLIENT debug node/<master_node>
#   [...]
#   sh-4.4# chroot /host bash
#   podman run --privileged --volume /var/lib/etcd:/test quay.io/peterducai/$ETCDNS-suite:latest fio


    # $ $CLIENT debug node/<master_node>
    # [...]
    # sh-4.4# chroot /host bash
    # [root@<master_node> /]# podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf
