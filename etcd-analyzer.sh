#/bin/bash

STAMP=$(date +%Y-%m-%d_%H-%M-%S)
CLIENT="oc"
ETCD_NS='openshift-etcd'
MUST_PATH=$1
ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA

rm -rf $OUTPUT_PATH
mkdir -p $OUTPUT_PATH

# PARSER --------------------------------------------------------------------------

print_help() {
  echo -e "HELP:"
  echo -e "-k | --kubectl : use kubectl instead of oc (not supported)"
  echo -e "-h | --help : print this help"
  echo -e ""
}

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -k|--kubectl)
      CLIENT="kubectl"
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

#/bin/bash

STAMP="$(echo $stamp|tr _ ' '|xargs -0 date -d)"

MASTERS=$($CLIENT get nodes |grep master|cut -d ' ' -f1)
ETCD=( $($CLIENT --as system:admin -n openshift-etcd get -l k8s-app=etcd pods -o name | tr -s '\n' ' ' | sed 's/pod\///g' ) )


echo -e ""
echo -e "-[${ETCD[0]}]--------------------"

echo -e ""
$CLIENT exec -n openshift-etcd ${ETCD[0]} -c etcdctl -- etcdctl endpoint status -w table
echo -e "IPs:"
for i in $($CLIENT exec ${ETCD[0]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do echo $i && oc exec -n openshift-etcd ${ETCD[0]} -c etcd -- ip a s|grep inet|grep -v inet6|grep -v '127.'|head -2; done
echo -e "Errors and dropped packets:"
for i in $($CLIENT exec ${ETCD[0]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do oc exec -n openshift-etcd ${ETCD[0]} -c etcd -- ip -s link show dev $i; done
echo -e ""
echo -e "Latency against API is $(curl -sk https://api.$(echo ${ETCD[0]}| sed 's/.*://').com -w "%{time_connect}\n"|tail -1)"
echo -e ""
echo -e "LOGS \nstart on $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|head -60|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e "ends on $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e ""
echo -e "Found $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|grep overloaded|wc -l) overloaded messages"
echo -e "Found $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|grep 'took too long'|wc -l) took too long messages"
echo -e "Found $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|grep 'slow fdatasync'|wc -l) slow fdatasync messages"
echo -e "Found $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|grep clock|wc -l) clock difference messages"
echo -e "Found $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|grep heartbeat|wc -l) heartbeat messages"
echo -e "Found $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|grep 'database space exceeded'|wc -l) database space exceeded messages"
echo -e "Found $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|grep 'leader changed'|wc -l) leader changed messages"
echo -e ""
echo -e "COMPACTION: \n$($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|grep compaction|tail -8|cut -d ':' -f10|cut -c 2-12)"
echo -e ""
echo -e "-[${ETCD[1]}]--------------------"
echo -e ""
$CLIENT exec -n openshift-etcd ${ETCD[1]} -c etcdctl -- etcdctl endpoint status -w table
echo -e ""
echo -e "IPs:"
for i in $($CLIENT exec ${ETCD[1]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do echo $i && oc exec -n openshift-etcd ${ETCD[1]} -c etcd -- ip a s|grep inet|grep -v inet6|grep -v '127.'|head -2; done
echo -e "Errors and dropped packets:"
for i in $($CLIENT exec ${ETCD[1]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do oc exec -n openshift-etcd ${ETCD[1]} -c etcd -- ip -s link show dev $i; done
echo -e ""
echo -e "Latency against API is $(curl -sk https://api.$(echo ${ETCD[1]}| sed 's/.*://').com -w "%{time_connect}\n"|tail -1)"
echo -e ""
echo -e "LOGS \nstart on $($CLIENT logs ${ETCD[1]} -c etcd -n openshift-etcd|head -60|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e "ends on $($CLIENT logs ${ETCD[1]} -c etcd -n openshift-etcd|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e ""
echo -e "Found $($CLIENT logs ${ETCD[1]} -c etcd -n openshift-etcd|grep overloaded|wc -l) overloaded messages"
echo -e "Found $($CLIENT logs ${ETCD[1]} -c etcd -n openshift-etcd|grep 'took too long'|wc -l) took too long messages"
echo -e "Found $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|grep 'slow fdatasync'|wc -l) slow fdatasync messages"
echo -e "Found $($CLIENT logs ${ETCD[1]} -c etcd -n openshift-etcd|grep clock|wc -l) clock difference messages"
echo -e "Found $($CLIENT logs ${ETCD[1]} -c etcd -n openshift-etcd|grep heartbeat|wc -l) heartbeat messages"
echo -e "Found $($CLIENT logs ${ETCD[1]} -c etcd -n openshift-etcd|grep 'database space exceeded'|wc -l) database space exceeded messages"
echo -e "Found $($CLIENT logs ${ETCD[1]} -c etcd -n openshift-etcd|grep 'leader changed'|wc -l) leader changed messages"
echo -e ""
echo -e "COMPACTION: \n$($CLIENT logs ${ETCD[1]} -c etcd -n openshift-etcd|grep compaction|tail -8|cut -d ':' -f10|cut -c 2-12)"
echo -e ""
echo -e "-[ ${ETCD[2]}]--------------------"
echo -e ""
$CLIENT exec -n openshift-etcd ${ETCD[2]} -c etcdctl -n openshift-etcd -- etcdctl endpoint status -w table
echo -e ""
echo -e "IPs:"
for i in $($CLIENT exec ${ETCD[2]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do echo $i && oc exec -n openshift-etcd ${ETCD[2]} -c etcd -- ip a s|grep inet|grep -v inet6|grep -v '127.'|head -2; done
echo -e "Errors and dropped packets:"
for i in $($CLIENT exec ${ETCD[2]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do oc exec -n openshift-etcd ${ETCD[2]} -c etcd -- ip -s link show dev $i; done
echo -e ""
echo -e "Latency against API is $(curl -sk https://api.$(echo ${ETCD[2]}| sed 's/.*://').com -w "%{time_connect}\n"|tail -1)"
echo -e ""
echo -e "LOGS \nstart on $($CLIENT logs ${ETCD[2]} -c etcd -n openshift-etcd|head -60|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e "ends on $($CLIENT logs ${ETCD[2]} -c etcd -n openshift-etcd|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e ""
echo -e "Found $($CLIENT logs ${ETCD[2]} -c etcd -n openshift-etcd|grep overloaded|wc -l) overloaded messages"
echo -e "Found $($CLIENT logs ${ETCD[2]} -c etcd -n openshift-etcd|grep 'took too long'|wc -l) took too long messages"
echo -e "Found $($CLIENT logs ${ETCD[0]} -c etcd -n openshift-etcd|grep 'slow fdatasync'|wc -l) slow fdatasync messages"
echo -e "Found $($CLIENT logs ${ETCD[2]} -c etcd -n openshift-etcd|grep clock|wc -l) clock difference messages"
echo -e "Found $($CLIENT logs ${ETCD[2]} -c etcd -n openshift-etcd|grep heartbeat|wc -l) heartbeat messages"
echo -e "Found $($CLIENT logs ${ETCD[2]} -c etcd -n openshift-etcd|grep 'database space exceeded'|wc -l) database space exceeded messages"
echo -e "Found $($CLIENT logs ${ETCD[2]} -c etcd -n openshift-etcd|grep 'leader changed'|wc -l) leader changed messages"
echo -e ""
echo -e "COMPACTION: \n$($CLIENT logs ${ETCD[2]} -c etcd -n openshift-etcd|grep compaction|tail -8|cut -d ':' -f10|cut -c 2-12)"
echo -e ""

echo -e ""
echo -e "[NUMBER OF OBJECTS IN ETCD]"
echo -e ""
$CLIENT exec -n openshift-etcd ${ETCD[0]} -c etcdctl -n openshift-etcd -- etcdctl get / --prefix --keys-only | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn|head -14
echo -e ""

echo -e "[BIGGEST CONSUMERS]"
echo -e ""
$CLIENT exec -n openshift-etcd ${ETCD[0]} -c etcdctl -n openshift-etcd -- etcdctl get / --prefix --keys-only > keysonly.txt
cat keysonly.txt | grep event |cut -d/ -f3,4| sort | uniq -c | sort -n --rev |head -10
echo -e "..."
cat keysonly.txt | grep event |cut -d/ -f3,4,5| sort | uniq -c | sort -n --rev |head -10

# oc exec ${ETCD[0]}  -c etcdctl -n openshift-etcd --  etcdctl watch / --prefix  --write-out=fields > fields.txt













#   $ oc debug node/<master_node>
#   [...]
#   sh-4.4# chroot /host bash
#   podman run --privileged --volume /var/lib/etcd:/test quay.io/peterducai/openshift-etcd-suite:latest fio


    # $ oc debug node/<master_node>
    # [...]
    # sh-4.4# chroot /host bash
    # [root@<master_node> /]# podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf

# $CLIENT exec ${ETCD[0]}  -c etcdctl -n $ETCD_NS --  etcdctl watch / --prefix  --write-out=fields > fields.txt













#   $ $CLIENT debug node/<master_node>
#   [...]
#   sh-4.4# chroot /host bash
#   podman run --privileged --volume /var/lib/etcd:/test quay.io/peterducai/openshift-etcd-suite:latest fio


    # $ $CLIENT debug node/<master_node>
    # [...]
    # sh-4.4# chroot /host bash
    # [root@<master_node> /]# podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf