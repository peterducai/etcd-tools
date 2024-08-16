#!/bin/bash


for item in `oc get pod -n openshift-etcd --no-headers | awk '{print $1}'`
do
    echo "[POD]  $item"
    echo ""
    echo "overloaded network:"
    oc logs -n openshift-etcd $item |grep 'overload'|grep network|wc -l
    echo ""
    echo "overloaded disk:"
    oc logs -n openshift-etcd $item |grep 'overload'|grep disk|wc -l
    echo ""
    echo "clock difference:"
    oc logs -n openshift-etcd $item |grep 'clock difference'|wc -l
    echo ""
    echo "clock-drift:"
    oc logs -n openshift-etcd $item |grep 'clock-drift'|wc -l
    echo ""
    echo "apply request took too long:"
    oc logs -n openshift-etcd $item |grep 'apply request took too long'|wc -l
    echo ""
    echo "failed to send out heartbeat on time"
    oc logs -n openshift-etcd $item |grep 'failed to send out heartbeat on time'|wc -l
    echo ""
    echo "database space exceeded"
    oc logs -n openshift-etcd $item |grep 'database space exceeded'|wc -l
    echo ""
    echo "leader changed"
    oc logs -n openshift-etcd $item |grep 'leader changed'|wc -l
    echo ""
    echo ""
done


for item in `oc get pod -n openshift-ingress --no-headers | awk '{print $1}'`
do
    echo "[ROUTER POD]  $item"
    echo ""
    echo "Unexpected watch close:"
    oc logs -n openshift-ingress $item |grep 'Unexpected watch close'|wc -l
    echo ""
    echo "error on the server:"
    oc logs -n openshift-ingress $item |grep 'error on the server'|wc -l
    echo ""
    echo "context deadline exceeded:"
    oc logs -n openshift-ingress $item |grep 'context deadline exceeded'|wc -l
    echo ""
    echo "timeout:"
    oc logs -n openshift-ingress $item |grep 'timeout'|wc -l
    echo ""
    echo "process:"
    oc logs -n openshift-ingress $item |grep 'process'|wc -l
    echo ""
    echo "clock"
    oc logs -n openshift-ingress $item |grep 'clock'|wc -l
    echo ""
    echo "buffer:"
    oc logs -n openshift-ingress $item |grep 'buffer'|wc -l
    echo ""
    echo ""
done