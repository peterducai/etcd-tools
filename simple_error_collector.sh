#!/bin/bash

num=1 
echo -e "-ETCD----------------------------------------"
echo ""
for item in `oc get pod -n openshift-etcd --no-headers | awk '{print $1}'`
do
    echo "[ETCD POD $num]"
    echo ""
    echo "overloaded network: $(oc logs -n openshift-etcd $item |grep 'overload'|grep network|wc -l)"
    echo "overloaded disk: $(oc logs -n openshift-etcd $item |grep 'overload'|grep disk|wc -l)"
    echo "clock difference: $(oc logs -n openshift-etcd $item |grep 'clock difference'|wc -l)"
    echo "clock-drift: $(oc logs -n openshift-etcd $item |grep 'clock-drift'|wc -l)"
    echo "apply request took too long: $(oc logs -n openshift-etcd $item |grep 'apply request took too long'|wc -l)"
    echo "database space exceeded: $(oc logs -n openshift-etcd $item |grep 'database space exceeded'|wc -l)"
    echo "leader changed: $(oc logs -n openshift-etcd $item |grep 'leader changed'|wc -l)"    
    echo ""
    echo ""
    num=$(($num+1))
done


num=1
echo -e "-Routers----------------------------------------"
echo ""
for item in `oc get pod -n openshift-ingress --no-headers | awk '{print $1}'`
do
    echo "[ROUTER POD $num]"
    echo ""
    echo "Unexpected watch close: $(oc logs -n openshift-ingress $item |grep 'Unexpected watch close'|wc -l)"    
    echo "error on the server: $(oc logs -n openshift-ingress $item |grep 'error on the server'|wc -l)"    
    echo "context deadline exceeded: $(oc logs -n openshift-ingress $item |grep 'context deadline exceeded'|wc -l)"    
    echo "timeout: $(oc logs -n openshift-ingress $item |grep 'timeout'|wc -l)"    
    echo "process: $(oc logs -n openshift-ingress $item |grep 'process'|wc -l)"    
    echo "clock: $(oc logs -n openshift-ingress $item |grep 'clock'|wc -l)"    
    echo "buffer: $(oc logs -n openshift-ingress $item |grep 'buffer'|wc -l)"    
    echo ""
    echo ""
    num=$(($num+1))
done

num=1
echo -e "-Apiserver----------------------------------------"
echo ""
for item in `oc get pod -n openshift-kube-apiserver --no-headers|grep -i running | awk '{print $1}'`
do
    echo "[APISERVER POD $num]"
    echo ""
    echo "timed out: $(oc logs -n openshift-kube-apiserver $item |grep 'timed out'|wc -l)"
    echo "context deadline exceeded: $(oc logs -n openshift-kube-apiserver $item |grep 'deadline exceeded'|wc -l)"
    echo "timeout: $(oc logs -n openshift-kube-apiserver $item  |grep 'timeout'|wc -l)"
    echo "process: $(oc logs -n openshift-kube-apiserver $item  |grep 'process'|wc -l)"
    echo "clock: $(oc logs -n openshift-kube-apiserver $item  |grep 'clock'|wc -l)"    
    echo "buffer: $(oc logs -n openshift-kube-apiserver $item  |grep 'buffer'|wc -l)"    
    echo ""
    echo ""
    num=$(($num+1))
done


num=1
echo -e "-Network operator----------------------------------------"
echo ""
for item in `oc get pod -n openshift-network-operator --no-headers|grep -i running | awk '{print $1}'`
do
    echo "[Network Operator POD $num]"
    echo ""
    echo "timed out: $(oc logs -n openshift-network-operator $item |grep 'timed out'|wc -l)"
    echo "context deadline exceeded: $(oc logs -n openshift-network-operator $item |grep 'deadline exceeded'|wc -l)"
    echo "timeout: $(oc logs -n openshift-network-operator $item  |grep 'timeout'|wc -l)"
    echo "process: $(oc logs -n openshift-network-operator $item  |grep 'process'|wc -l)"
    echo "clock: $(oc logs -n openshift-network-operator $item  |grep 'clock'|wc -l)"    
    echo "buffer: $(oc logs -n openshift-network-operator $item  |grep 'error adding container to network'|wc -l)"    
    echo "buffer: $(oc logs -n openshift-network-operator $item  |grep 'error adding container to network'|wc -l)"   
    echo ""
    echo ""
    num=$(($num+1))
done


num=1
echo -e "-OVN----------------------------------------"
echo ""
for item in `oc get pod -n openshift-ovn-kubernetes --no-headers|grep node|grep -i running | awk '{print $1}'`
do
    echo "[OVN POD $num NORTHDB]"
    echo ""
    echo "Unreasonably long poll interval: $(oc logs -n openshift-ovn-kubernetes $item -c northd |grep 'Unreasonably long'|wc -l)"
    echo "timeout at: $(oc logs -n openshift-ovn-kubernetes $item -c northd |grep 'timeout at'|wc -l)"    
    echo "OVNNB/SB commit failed, force recompute next time: $(oc logs -n openshift-ovn-kubernetes $item -c northd |grep 'commit failed'|wc -l)"    
    echo "no response to inactivity probe: $(oc logs -n openshift-ovn-kubernetes $item -c northd |grep 'no response to inactivity probe'|wc -l)"   
    echo ""
    echo ""
    num=$(($num+1))
done

# pods.go:40] Couldn't allocate IPs: 10.129.0.4 for pod: (overlapping PodIPs)
# addLogicalPort took 963.236483ms (very long addLogicalPort times)
# setup retry failed; will try again later (something failed in addLogicalPort)



num=1
echo -e "-Machine Configs----------------------------------------"
echo ""
for node in $(oc get nodes -o name | awk -F'/' '{ print $2 }')
do
  echo "[NODE $num]"
  oc describe node $node | grep machineconfiguration.openshift.io/state
  num=$(($num+1))
done