#/bin/bash

STAMP="$(echo $stamp|tr _ ' '|xargs -0 date -d)"

MASTERS=$(oc get nodes |grep master|cut -d ' ' -f1)
ETCD=( $(oc --as system:admin -n openshift-etcd get -l k8s-app=etcd pods -o name | tr -s '\n' ' ' ) )


echo -e ""
echo -e "-[${ETCD[0]}]--------------------"

echo -e ""
oc exec ${ETCD[0]} -c etcdctl -- etcdctl endpoint status -w table
echo -e "IPs:"
for i in $(oc exec ${ETCD[0]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do echo $i && oc exec ${ETCD[0]} -c etcd -- ip a s|grep inet|grep -v inet6|grep -v '127.'|head -2; done
echo -e "Errors and dropped packets:"
for i in $(oc exec ${ETCD[0]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do oc exec ${ETCD[0]} -c etcd -- ip -s link show dev $i; done
echo -e ""
echo -e "Latency against API is $(curl -k https://api.$(echo ${ETCD[0]}| sed 's/.*://').com -w "%{time_connect}\n"|tail -1)"
echo -e ""
echo -e "LOGS \nstart on $(oc logs ${ETCD[0]} -c etcd -n openshift-etcd|head -60|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e "ends on $(oc logs ${ETCD[0]} -c etcd -n openshift-etcd|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e ""
echo -e "Found $(oc logs ${ETCD[0]} -c etcd -n openshift-etcd|grep overloaded|wc -l) overloaded messages"
echo -e "Found $(oc logs ${ETCD[0]} -c etcd -n openshift-etcd|grep 'took too long'|wc -l) took too long messages"
echo -e "Found $(oc logs ${ETCD[0]} -c etcd -n openshift-etcd|grep clock|wc -l) clock difference messages"
echo -e "Found $(oc logs ${ETCD[0]} -c etcd -n openshift-etcd|grep heartbeat|wc -l) heartbeat messages"
echo -e "Found $(oc logs ${ETCD[0]} -c etcd -n openshift-etcd|grep 'database space exceeded'|wc -l) database space exceeded messages"
echo -e "Found $(oc logs ${ETCD[0]} -c etcd -n openshift-etcd|grep 'leader changed'|wc -l) leader changed messages"
echo -e ""
echo -e "COMPACTION: \n$(oc logs ${ETCD[0]} -c etcd -n openshift-etcd|grep compaction|tail -8|cut -d ':' -f10|cut -c 2-12)"
echo -e ""
echo -e "-[${ETCD[1]}]--------------------"
echo -e ""
oc exec ${ETCD[1]} -c etcdctl -- etcdctl endpoint status -w table
echo -e ""
echo -e "IPs:"
for i in $(oc exec ${ETCD[1]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do echo $i && oc exec ${ETCD[1]} -c etcd -- ip a s|grep inet|grep -v inet6|grep -v '127.'|head -2; done
echo -e "Errors and dropped packets:"
for i in $(oc exec ${ETCD[1]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do oc exec ${ETCD[1]} -c etcd -- ip -s link show dev $i; done
echo -e ""
echo -e "Latency against API is $(curl -k https://api.$(echo ${ETCD[1]}| sed 's/.*://').com -w "%{time_connect}\n"|tail -1)"
echo -e ""
echo -e "LOGS \nstart on $(oc logs ${ETCD[1]} -c etcd -n openshift-etcd|head -60|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e "ends on $(oc logs ${ETCD[1]} -c etcd -n openshift-etcd|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e ""
echo -e "Found $(oc logs ${ETCD[1]} -c etcd -n openshift-etcd|grep overloaded|wc -l) overloaded messages"
echo -e "Found $(oc logs ${ETCD[1]} -c etcd -n openshift-etcd|grep 'took too long'|wc -l) took too long messages"
echo -e "Found $(oc logs ${ETCD[1]} -c etcd -n openshift-etcd|grep clock|wc -l) clock difference messages"
echo -e "Found $(oc logs ${ETCD[1]} -c etcd -n openshift-etcd|grep heartbeat|wc -l) heartbeat messages"
echo -e "Found $(oc logs ${ETCD[1]} -c etcd -n openshift-etcd|grep 'database space exceeded'|wc -l) database space exceeded messages"
echo -e "Found $(oc logs ${ETCD[1]} -c etcd -n openshift-etcd|grep 'leader changed'|wc -l) leader changed messages"
echo -e ""
echo -e "COMPACTION: \n$(oc logs ${ETCD[1]} -c etcd -n openshift-etcd|grep compaction|tail -8|cut -d ':' -f10|cut -c 2-12)"
echo -e ""
echo -e "-[echo ${ETCD[2]}]--------------------"
echo -e ""
oc exec ${ETCD[2]} -c etcdctl -n openshift-etcd -- etcdctl endpoint status -w table
echo -e ""
echo -e "IPs:"
for i in $(oc exec ${ETCD[2]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do echo $i && oc exec ${ETCD[2]} -c etcd -- ip a s|grep inet|grep -v inet6|grep -v '127.'|head -2; done
echo -e "Errors and dropped packets:"
for i in $(oc exec ${ETCD[2]} -c etcd -n openshift-etcd -- ls /sys/class/net|grep -v veth|grep -v lo); do oc exec ${ETCD[2]} -c etcd -- ip -s link show dev $i; done
echo -e ""
echo -e "Latency against API is $(curl -k https://api.$(echo ${ETCD[2]}| sed 's/.*://').com -w "%{time_connect}\n"|tail -1)"
echo -e ""
echo -e "LOGS \nstart on $(oc logs ${ETCD[2]} -c etcd -n openshift-etcd|head -60|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e "ends on $(oc logs ${ETCD[2]} -c etcd -n openshift-etcd|tail -1|cut -d ':' -f3|cut -c 2-14)"
echo -e ""
echo -e "Found $(oc logs ${ETCD[2]} -c etcd -n openshift-etcd|grep overloaded|wc -l) overloaded messages"
echo -e "Found $(oc logs ${ETCD[2]} -c etcd -n openshift-etcd|grep 'took too long'|wc -l) took too long messages"
echo -e "Found $(oc logs ${ETCD[2]} -c etcd -n openshift-etcd|grep clock|wc -l) clock difference messages"
echo -e "Found $(oc logs ${ETCD[2]} -c etcd -n openshift-etcd|grep heartbeat|wc -l) heartbeat messages"
echo -e "Found $(oc logs ${ETCD[2]} -c etcd -n openshift-etcd|grep 'database space exceeded'|wc -l) database space exceeded messages"
echo -e "Found $(oc logs ${ETCD[2]} -c etcd -n openshift-etcd|grep 'leader changed'|wc -l) leader changed messages"
echo -e ""
echo -e "COMPACTION: \n$(oc logs ${ETCD[2]} -c etcd -n openshift-etcd|grep compaction|tail -8|cut -d ':' -f10|cut -c 2-12)"
echo -e ""

echo -e ""
echo -e "[NUMBER OF OBJECTS IN ETCD]"
echo -e ""
oc exec ${ETCD[0]} -c etcdctl -n openshift-etcd -- etcdctl get / --prefix --keys-only | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn|head -14
echo -e ""

echo -e "[BIGGEST CONSUMERS]"
echo -e ""
oc exec ${ETCD[0]} -c etcdctl -n openshift-etcd -- etcdctl get / --prefix --keys-only > keysonly.txt
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