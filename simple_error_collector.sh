#!/bin/bash

num=1 

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