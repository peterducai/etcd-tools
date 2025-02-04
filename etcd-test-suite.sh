#!/bin/bash

################################################################################
#                               ETCD test suite                                #
#                                                                              #
# Script for testing performance of OCP cluster                                #
#                                                                              #
#                                                                              #
################################################################################
################################################################################
################################################################################
#                                                                              #
#  Copyright (C) 2025 Peter Ducai                                              #
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

ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA



# TEST VALUES

declare -A NIC
declare -A NIC2
declare -A ETCD_OBJECTS
declare -A ETCD_OBJECTS2




MASTERS=$($CLIENT get nodes |grep master|cut -d ' ' -f1)
ETCD=( $($CLIENT --as system:admin -n $ETCDNS get -l k8s-app=etcd pods -o name | tr -s '\n' ' ' | sed 's/pod\///g' ) )
#API=$( oc config view --minify -o jsonpath='{.clusters[*].cluster.server}' )
# API=$( $CLIENT get cm console-config -n openshift-console -o jsonpath="{.data.console-config\.yaml}" | grep masterPublicURL | awk '{print $2}' )
# echo -e "API URL: $API"
# TOKEN=$(oc whoami -t)



object_size() {
  for i in $(oc get pod -n openshift-etcd|grep -v guard|tail -3|awk ' { print $1 }')
  do
    echo -e ""
    echo -e "[NUMBER OF OBJECTS IN ETCD]  $(date +%Y-%m-%d_%H:%M:%S)"
    echo -e ""
    $CLIENT exec -n $ETCDNS $i -c etcdctl -n $ETCDNS -- etcdctl get / --prefix --keys-only > keysonly.txt
    cat keysonly.txt | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn|head -14


    #TODO
    # cat peptides.txt | while read line 
    # do
    #   ETCD_OBJECTS["$i.etcd_objects.$j.drop_rx"]=$number
    # done
    
    # echo -e "       ..."
    # cat keysonly.txt | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn|tail -6
    # echo -e ""
    
    # echo -e ""
    # echo -e "[size of objects in ETCD]"
    # echo -e ""
    # oc exec -n $ETCDNS $i -c etcdctl -- sh -c "etcdctl get / --prefix --keys-only  | grep -oE '^/[a-z|.]+/[a-z|.|8]*' | sort | uniq" | while read KEY; do printf "$KEY\t" && oc exec -n openshift-etcd $i -c etcdctl -- etcdctl get $KEY --prefix --write-out=json | jq '[.kvs[].value | length] | add ' | numfmt --to=iec ; done | sort -k2 -hr | column -t
    # echo -e ""
    return
  done
}

dropped_packet_check() {
  echo -e "[NICs] $(date +%Y-%m-%d_%H:%M:%S)\n"
  
  for i in $(oc get pod -n openshift-etcd|grep -v guard|tail -3|awk ' { print $1 }')
  do 
    echo -e "[$i]\n"
    for j in $(oc exec $i -n openshift-etcd -c etcd -- ip -4 -brief address show|awk ' { print $1 }')
    do 
      echo "$j"
      IPLINK=$(oc exec $i -c etcd -n openshift-etcd  -- ip -s link show dev $j)
      # NIC["$i.$j"]=$IPLINK
      # echo "-----------------------------------"
      # echo $IPLINK
      # echo "-----------------------------------"
      # echo $IPLINK|awk ' { print $30 } '|tail -2
      # echo "-----------------------------------"
      DROPRX=$(echo $IPLINK|awk ' { print $30 } '|tail -1|head -1)
      NIC["$i.nic.$j.drop_rx"]=$DROPRX
      if [[ $DROPRX > 0 ]]; then
        echo -e "    Dropped RX: $DROPRX"
      fi

      # ERRRX=$(echo $IPLINK||awk ' { print $29 } '|tail -1|head -1)
      # if [[ $ERRRX > 0 ]]; then
      #   echo -e "    Error RX: $ERRRX"
      # fi
      #echo -e "    Error RX: $ERRRX"
      
      DROPTX=$(echo $IPLINK|awk ' { print $43 } '|tail -3|head -1)
      NIC["$i.$j.drop_tx"]=$DROPTX
      if [[ $DROPTX > 0 ]]; then
        echo -e "    Dropped TX: $DROPTX"
      fi

      # ERRTX=$(echo $IPLINK||awk ' { print $42 } '|tail -3|head -1)
      # if [[ $ERRTX > 0 ]]; then
      #   echo -e "    Error TX: $ERRTX"
      # fi
      
    done
  done

  # PRINT NIC()
  # printf -v fmtStr '[%s]=%%q\\n' "${!NIC[@]}";printf "$fmtStr" "${NIC[@]}"
}

# compare 2 arrays

#echo ${Array1[@]} ${Array1[@]} ${Array2[@]} | tr ' ' '\n' | sort | uniq -u

object_size
dropped_packet_check
object_size





# 

# ip -s link show crc|tail -4|tail -1|awk ' { print "TX_errors:" $3 }'
# ip -s link show crc|tail -4|tail -1|awk ' { print "TX_dropped:" $4 }'

# ip -s link show crc|tail -4|head -2|tail -1|awk ' { print "RX_errors:" $3 }'
# ip -s link show crc|tail -4|head -2|tail -1|awk ' { print "RX_errors:" $34 }'






# for i in $(oc get pod -n openshift-etcd|grep -v guard|awk ' { print $1 }'); do echo "checking $i"; 
# for j in $(oc exec $j -n openshift-etcd -c etcd -- ip link show|awk 'NR%2==1'|awk ' { print $2 }'| rev | cut -c2- | rev); 
# do echo "checking $j";
# echo $(oc exec $i -c etcd -n openshift-etcd  -- ip -s link show -d $j); done;




#  echo $(oc exec $i -c etcd -n openshift-etcd  -- ip -s link show ); done






# for i in $(oc get pod -n openshift-etcd|grep -v guard|tail -3|awk ' { print $1 }'); do echo "checking $i"; for j in $(oc exec $i -n openshift-etcd -c etcd -- ip link show|awk 'NR%2==1'|awk ' { print $2 }'| rev | cut -c2- | rev); do echo "checking $j"; echo $(oc exec $i -c etcd -n openshift-etcd  -- ip -s link show -d $j); done; done;


#WORKING


















# compaction_test() {

# cat comp.txt| while read line 
# do
#    CHECK=$(echo $line |tail -12|cut -d ':' -f10| rev | cut -c9- | rev|cut -c2- |grep -E '[0-9]')
#    #echo $CHECK |grep -E '[0-9]s'
#    #[ -z "$(echo $CHECK |grep -E '[0-9]s')" ] && echo $CHECK
#    [[ ! -z "$(echo $CHECK |grep -E '[0-9]s')" ]] && echo "$CHECK <---- TOO HIGH!" || echo $CHECK
# done
# }

# overload_test() {
#   echo -e ""
#   $CLIENT logs $i -c etcd -n $ETCDNS|grep overloaded > $OUTPUT_PATH/over.txt
#   LAST=$(cat $OUTPUT_PATH/over.txt|tail -1 |cut -d ':' -f3|cut -c 2-11)
#   LOGEND=$(cat $OUTPUT_PATH/over.txt|tail -1 |cut -d ':' -f3|cut -c 2-11)

#   if [[ "$(cat $OUTPUT_PATH/over.txt|wc -l)" -eq 0 ]];
#   then
#      echo "no overloaded message - EXCELLENT!"
#   else
#     echo -e "Found $(cat $OUTPUT_PATH/over.txt|grep overloaded |wc -l) overloaded messages while there should be zero of them.. last seen on $LOGEND"
#     OVERLOADN=$(cat $OUTPUT_PATH/over.txt|grep 'overload'|grep network|wc -l)
#     OVERLOADC=$(cat $OUTPUT_PATH/over.txt|grep 'overload'|grep disk|wc -l)
#     echo -e "$OVERLOADN x OVERLOADED NETWORK in $1  (high network or remote storage latency)"
#     echo -e "$OVERLOADC x OVERLOADED DISK/CPU in $1  (slow storage or lack of CPU on masters)"
#   fi
#   echo -e ""
# }

# leaderchanged_test_tooktoolong() {
#   $CLIENT logs $i -c etcd -n $ETCDNS|grep 'leader changed' > $OUTPUT_PATH/leaderchanged.txt
#   LAST=$(cat $OUTPUT_PATH/leaderchanged.txt|tail -1cut -d ':' -f3|cut -c 2-11)
#   LOGEND=$(cat $OUTPUT_PATH/leaderchanged.txt|tail -1cut -d ':' -f3|cut -c 2-11)
  
#   echo -e "Found $(cat $OUTPUT_PATH/leaderchanged.txt|wc -l) took too long due to leader changed messages.. last seen on $LOGEND"
# }

# leaderchanged_test() {
#   $CLIENT logs $i -c etcd -n $ETCDNS|grep 'elected leader' > $OUTPUT_PATH/elected.txt
#   LAST=$(cat $OUTPUT_PATH/elected.txt|tail -1|cut -d ':' -f3|cut -c 2-11)
#   LOGEND=$(cat $OUTPUT_PATH/elected.txt|tail -1|cut -d ':' -f3|cut -c 2-11)
  
#   echo -e "Found $(cat $OUTPUT_PATH/elected.txt|wc -l) took too long due to leader changed messages.. last seen on $LOGEND"
# }

# analyze_members() {
#   for i in ${ETCD[@]}; do
#     echo -e ""
#     echo -e "-[$i]--------------------"
    
#     echo -e ""
#     $CLIENT exec -n $ETCDNS $i -c etcdctl -- etcdctl endpoint status -w table
#     echo -e "IPs:"
#     for j in $($CLIENT exec $i -c etcd -n $ETCDNS -- ls /sys/class/net|grep -v veth|grep -v lo); do echo $j && oc exec -n $ETCDNS $i -c etcd -- ip a s|grep inet|grep -v inet6|grep -v '127.'|head -2; done
#     echo -e "Errors and dropped packets:"
#     for j in $($CLIENT exec $i -c etcd -n $ETCDNS -- ls /sys/class/net|grep -v veth|grep -v lo); do oc exec -n $ETCDNS $i -c etcd -- ip -s link show dev $j; done
#     echo -e ""
# #    echo -e "Latency against API is $(curl -sk $API -w "%{time_connect}\n"|tail -1) .  Should be close to 0.002 (2ms) and no more than 0.008 (8ms)."
#     echo -e "Latency against API is $(curl -sk -H "Authorization: Bearer $TOKEN" -X GET $API -w "%{time_connect}\n" --output /dev/null) .  Should be close to 0.002 (2ms) and no more than 0.008 (8ms)."
#     echo -e ""
#     echo -e ""
#     echo -e "LOGS \nstart on $($CLIENT logs $i -c etcd -n $ETCDNS|head -60|tail -1|cut -d ':' -f3|cut -c 2-14)"
#     echo -e "ends on $($CLIENT logs $i -c etcd -n $ETCDNS|tail -1|cut -d ':' -f3|cut -c 2-14)"
#     echo -e ""
    
#     overload_test

#     echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep 'took too long'|wc -l) took too long messages"
#     echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep 'slow fdatasync'|wc -l) slow fdatasync messages"
#     echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep clock|wc -l) clock difference messages"
#     echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep heartbeat|wc -l) heartbeat messages"
#     echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep 'database space exceeded'|wc -l) database space exceeded messages"
#     leaderchanged_test
    
#     echo -e "Found $($CLIENT logs $i -c etcd -n $ETCDNS|grep 'elected leader'|wc -l) leader changed messages"
#     echo -e ""
#     $CLIENT logs $i -c etcd -n $ETCDNS|grep compaction > comp.txt
#     echo -e "COMPACTION:"
#     compaction_test
#     echo -e ""
#     echo -e "---------------------"
#     echo -e ""
#   done
  
# }




# analyze_members





# echo -e ""
# echo -e "[NUMBER OF OBJECTS IN ETCD]"
# echo -e ""
# $CLIENT exec -n $ETCDNS $i -c etcdctl -n $ETCDNS -- etcdctl get / --prefix --keys-only > keysonly.txt
# cat keysonly.txt | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn|head -14
# echo -e "       ..."
# cat keysonly.txt | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn|tail -6
# echo -e ""

# echo -e ""
# echo -e "[size of objects in ETCD]"
# echo -e ""
# oc exec -n $ETCDNS $i -c etcdctl -- sh -c "etcdctl get / --prefix --keys-only  | grep -oE '^/[a-z|.]+/[a-z|.|8]*' | sort | uniq" | while read KEY; do printf "$KEY\t" && oc exec -n openshift-etcd $ETCD -c etcdctl -- etcdctl get $KEY --prefix --write-out=json | jq '[.kvs[].value | length] | add ' | numfmt --to=iec ; done | sort -k2 -hr | column -t
# echo -e ""

# echo -e "[MOST EVENTS keys]"
# echo -e ""
# cat keysonly.txt|grep event  |cut -d/ -f3,4| sort | uniq -c | sort -n --rev| head -14
# echo -e "      ..."
# cat keysonly.txt|grep event  |cut -d/ -f3-4| sort | uniq -c | sort -n --rev| tail -6
# echo -e ""
# cat keysonly.txt|grep event  |cut -d/ -f3,5| sort | uniq -c | sort -n --rev| head -14
# echo -e "      ..."
# cat keysonly.txt|grep event  |cut -d/ -f3-5| sort | uniq -c | sort -n --rev| tail -6
# #cat keysonly.txt | grep event |cut -d/ -f3,4,5| sort | uniq -c | sort -n --rev |head -10

# # oc exec $i  -c etcdctl -n $ETCDNS --  etcdctl watch / --prefix  --write-out=fields > fields.txt

# if [ $CLIENT == "kubectl" ]; then
#   return
# fi

# echo -e ""
# echo -e "[API CONSUMERS kube-apiserver on masters]"
# echo -e ""
# AUDIT_LOGS=$(oc adm node-logs --role=master --path=kube-apiserver|grep audit-)
# node=""
# for i in $AUDIT_LOGS; do
#   echo -e "[ processing $i ]"
#   if [[ $i == *".log"* ]]; then
#     oc adm node-logs $node --path=kube-apiserver/$i > $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2)
#     cat $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2) |jq '.user.username' -r > $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2).username
#     sort $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2).username | uniq -c | sort -bgr|head -5
#     echo -e ""
#   else
#     node=$i
#     continue
#   fi

# done;



# echo -e ""
# echo -e "-------------------------------------------------------------------------------"
# echo -e ""
# echo -e ""
# echo -e "[API CONSUMERS openshift-apiserver on masters]"
# echo -e ""
# AUDIT_LOGS=$(oc adm node-logs --role=master --path=openshift-apiserver|grep audit-)
# node=""
# for i in $AUDIT_LOGS; do
#   echo -e "[ processing $i ]"
#   if [[ $i == *".log"* ]]; then
#     oc adm node-logs $node --path=openshift-apiserver/$i > $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2)
#     cat $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2) |jq '.user.username' -r > $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2).username
#     sort $OUTPUT_PATH/$(echo $i|cut -d ' ' -f2).username | uniq -c | sort -bgr |head -5
#     echo -e ""
#   else
#     node=$i
#     continue
#   fi

# done;










# # oc describe nodes  | awk 'BEGIN{ovnsubnet="";printf "|%s|||||%s|||||%s||%s\n%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n","CPU","MEM","PODs","OVN","NODENAME","Allocatable","Request","(%)","Limit","(%)","Allocatable","Request","(%)","Limit","(%)","Allocatable","Running","Node Subnet"}{if($1 == "Name:"){name=$2};if($1 == "k8s.ovn.org/node-subnets:"){ovnsubnet=$2};if($1 ~ "Allocatable:"){while($1 != "System"){if($1 == "cpu:"){Alloc_cpu=$2};if($1 == "memory:"){Alloc_mem=$2};if($1 == "pods:"){Alloc_pod=$2};getline}};if($1 == "Namespace"){getline;getline;pods_count=0;while($1 != "Allocated"){pods_count++;getline}};if($1 == "Resource"){while($1 != "Events:"){if($1 == "cpu"){req_cpu=$2;preq_cpu=$3;lim_cpu=$4;plim_cpu=$5};if($1 == "memory"){req_mem=$2;preq_mem=$3;lim_mem=$4;plim_mem=$5};getline};printf "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n",name,Alloc_cpu,req_cpu,preq_cpu,lim_cpu,plim_cpu,Alloc_mem,req_mem,preq_mem,lim_mem,plim_mem,Alloc_pod,pods_count,ovnsubnet}}' | sed -e "s/{\"default\":\[\{0,1\}\"\([.\/0-9]*\)\"\]\{0,1\}\]}/\1/" | column -s'|' -t








# #   $ oc debug node/<master_node>
# #   [...]
# #   sh-4.4# chroot /host bash
# #   podman run --privileged --volume /var/lib/etcd:/test quay.io/peterducai/$ETCDNS-suite:latest fio


#     # $ oc debug node/<master_node>
#     # [...]
#     # sh-4.4# chroot /host bash
#     # [root@<master_node> /]# podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf

# # $CLIENT exec $i  -c etcdctl -n $ETCD_NS --  etcdctl watch / --prefix  --write-out=fields > fields.txt













# #   $ $CLIENT debug node/<master_node>
# #   [...]
# #   sh-4.4# chroot /host bash
# #   podman run --privileged --volume /var/lib/etcd:/test quay.io/peterducai/$ETCDNS-suite:latest fio


#     # $ $CLIENT debug node/<master_node>
#     # [...]
#     # sh-4.4# chroot /host bash
#     # [root@<master_node> /]# podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf






# # echo -e " etcd health and size"
# # for POD in $(oc get pod -n openshift-etcd | awk '/etcd-/ {print $1}' | grep -v quorum | grep -v guard); do
# #     echo "   $POD"
# #     echo "$POD" &> ${DIR}/etcd_status_health_"$POD".out
# #     oc -n openshift-etcd exec -c etcd "$POD" -- /bin/bash -c "etcdctl member list -w table;
# #     echo "---"; 
# #     etcdctl endpoint status -w table; 
# #     echo "---";
# #     etcdctl endpoint health -w table" &> ${DIR}/etcd_status_health_"$POD".out
# # done 

# # echo -e " etcd metrics"
# # echo -e " ...  metric etcd_disk_wal_fsync_duration"

# # curl -g -k -H "Authorization: Bearer $($prometheusTokenCommand)" https://"$PROMETHEUS_ROUTE"/api/v1/query? --data-urlencode 'query=histogram_quantile(0.99, sum(rate(etcd_disk_wal_fsync_duration_seconds_bucket{job="etcd"}[5m])) by (instance, le))' > ${DIR}/etcd_disk_wal_fsync_duration_seconds_bucket_99.json 2> ${DIR}/etcd_disk_wal_fsync_duration_seconds_bucket_err.json

# # curl -g -k -H "Authorization: Bearer $($prometheusTokenCommand)" https://"$PROMETHEUS_ROUTE"/api/v1/query? --data-urlencode 'query=histogram_quantile(0.999, sum(rate(etcd_disk_wal_fsync_duration_seconds_bucket{job="etcd"}[5m])) by (instance, le))' > ${DIR}/etcd_disk_wal_fsync_duration_seconds_bucket_999.json 2> ${DIR}/etcd_disk_wal_fsync_duration_seconds_bucket_err.json
# # ###

# # echo -e " ...  metric etcd_disk_backend_commit_duration"
# # curl -g -k -H "Authorization: Bearer $($prometheusTokenCommand)" https://"$PROMETHEUS_ROUTE"/api/v1/query? --data-urlencode 'query=histogram_quantile(0.99, sum(rate(etcd_disk_backend_commit_duration_seconds_bucket{job="etcd"}[5m])) by (instance, le))' > ${DIR}/etcd_disk_backend_commit_duration_seconds_bucket_99.json 2> ${DIR}/etcd_disk_backend_commit_duration_seconds_bucket_err.json

# # curl -g -k -H "Authorization: Bearer $($prometheusTokenCommand)" https://"$PROMETHEUS_ROUTE"/api/v1/query? --data-urlencode 'query=histogram_quantile(0.999, sum(rate(etcd_disk_backend_commit_duration_seconds_bucket{job="etcd"}[5m])) by (instance, le))' > ${DIR}/etcd_disk_backend_commit_duration_seconds_bucket_999.json 2> ${DIR}/etcd_disk_backend_commit_duration_seconds_bucket_err.json

# # echo -e " ...  metric for cpu iowait"
# # curl -g -k -H "Authorization: Bearer $($prometheusTokenCommand)" https://"$PROMETHEUS_ROUTE"/api/v1/query? --data-urlencode 'query=(sum(irate(node_cpu_seconds_total {mode="iowait"} [2m])) without (cpu)) / count(node_cpu_seconds_total) without (cpu) * 100 AND on (instance) label_replace( kube_node_role{role="master"}, "instance", "$1", "node", "(.+)" )' > ${DIR}/etcd_cpu_iowait.json 2> ${DIR}/etcd_cpu_iowait_err.json

# # echo -e " ...  metric etcd_network_peer_round_trip_time"
# # curl -g -k -H "Authorization: Bearer $($prometheusTokenCommand)" https://"$PROMETHEUS_ROUTE"/api/v1/query? --data-urlencode 'query=histogram_quantile(0.99, irate(etcd_network_peer_round_trip_time_seconds_bucket[5m]))' > ${DIR}/etcd_etcd_network_peer_round_trip_time_99.json 2> ${DIR}/etcd_etcd_network_peer_round_trip_time_err.json

# # curl -g -k -H "Authorization: Bearer $($prometheusTokenCommand)" https://"$PROMETHEUS_ROUTE"/api/v1/query? --data-urlencode 'query=histogram_quantile(0.999, irate(etcd_network_peer_round_trip_time_seconds_bucket[5m]))' > ${DIR}/etcd_etcd_network_peer_round_trip_time_999.json 2> ${DIR}/etcd_etcd_network_peer_round_trip_time_err.json
# # ###

# # echo -e " ...  openshift-etcd alerts firing"
# # curl -g -k -H "Authorization: Bearer $($prometheusTokenCommand)" https://"$PROMETHEUS_ROUTE"/api/v1/query? --data-urlencode 'query=count_over_time(ALERTS{namespace="openshift-etcd", alertstate="firing"}[2w])' > ${DIR}/etcd_firing_alerts.json 2> ${DIR}/etcd__firing_alerts_err.json