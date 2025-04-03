#!/bin/bash

num=1 
echo -e "-------------------"
echo -e "- ETCD ------------"
echo -e "-------------------"
echo ""
for item in `oc get pod -n openshift-etcd --no-headers | awk '{print $1}'`
do
    echo "[ETCD POD $num]"
    echo ""
    OVERNET=$(oc logs -n openshift-etcd $item |grep 'overload'|grep network|wc -l)
    OVERDISK=$(oc logs -n openshift-etcd $item |grep 'overload'|grep disk|wc -l)
    CLOCKDIF=$(oc logs -n openshift-etcd $item |grep 'clock difference'|wc -l)
    CLOCKDRIFT=$(oc logs -n openshift-etcd $item |grep 'clock-drift'|wc -l)
    TOOKTOOLONG=$(oc logs -n openshift-etcd $item |grep 'apply request took too long'|wc -l)
    DBSPACE=$(oc logs -n openshift-etcd $item |grep 'database space exceeded'|wc -l)
    LEADERCHANGE=$(oc logs -n openshift-etcd $item |grep 'leader changed'|wc -l)

    if (( $OVERNET != 0 )); then
      echo "overloaded network: $OVERNET"
      continue
    fi
    if (( $OVERDISK != 0 )); then
      echo "overloaded disk: $OVERDISK"
      continue
    fi
    if (( $CLOCKDIF != 0 )); then
      echo "clock difference: $CLOCKDIF"
      continue
    fi
    if (( $CLOCKDRIFT != 0 )); then
      echo "clock-drift: $CLOCKDRIFT"
      continue
    fi
    if (( $TOOKTOOLONG != 0 )); then
      echo "apply request took too long: $TOOKTOOLONG"
      continue
    fi
    if (( $DBSPACE != 0 )); then
      echo "database space exceeded: $DBSPACE"
      continue
    fi
    if (( $LEADERCHANGE != 0 )); then
      echo "leader changed: $LEADERCHANGE"
      continue
    fi
    num=$(($num+1))
done
echo -e ""


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