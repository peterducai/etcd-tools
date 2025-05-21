#!/bin/bash



echo -e "NODES:"
echo -e ""
echo -e "masters: $(oc get node|grep -c master)"
echo -e "infra: $(oc get node|grep -c infra)"
echo -e "worker: $(oc get node|grep -c worker)"
echo -e ""
echo -e ""


num=1
echo ""
echo ""
echo -e "-------------------------------------------"
echo -e "- PodNetworkConnectivityCheck -------------"
echo -e "- oc get podnetworkconnectivitycheck -n openshift-network-diagnostics --no-headers -"
echo -e "-------------------------------------------"
echo ""
for item in `oc get podnetworkconnectivitycheck -n openshift-network-diagnostics --no-headers| awk '{print $1}'`
do
  TCPERRORS=$(oc get podnetworkconnectivitycheck  $item -n openshift-network-diagnostics -o yaml|grep -c TCPConnectError)
  #echo -e "$item: $TCPERRORS"
  # [ -n "${STRING}" ] && echo ${STRING}


  if [[ $item == *"to-kubernetes-apiserver-endpoint"* ]]; then
    echo "to-kubernetes-apiserver-endpoint-NODE: $TCPERRORS"
  fi
  if [[ $item == *"to-kubernetes-apiserver-service-cluster"* ]]; then
    echo "to-kubernetes-apiserver-service-cluster-NODE: $TCPERRORS"
  fi
  if [[ $item == *"to-kubernetes-default-service-cluster"* ]]; then
    echo "to-kubernetes-default-service-cluster-NODEum: $TCPERRORS"
  fi
  if [[ $item == *"to-load-balancer-api-external"* ]]; then
    echo "to-load-balancer-api-external-NODE: $TCPERRORS"
  fi
  if [[ $item == *"to-load-balancer-api-internal"* ]]; then
    echo "to-load-balancer-api-internal-NODE: $TCPERRORS"
  fi
  if [[ $item == *"to-network-check-target-service-cluster"* ]]; then
    echo "to-network-check-target-service-cluster-NODE: $TCPERRORS"
  fi
  if [[ $item == *"to-network-check-target-"* ]]; then
    if [[ $item != *"service-cluster"* ]]; then
      echo "to-network-check-target--NODE: $TCPERRORS"
    fi  
  fi
  if [[ $item == *"to-openshift-apiserver-endpoint"* ]]; then
    echo "to-openshift-apiserver-endpoint-NODE: $TCPERRORS"
  fi
  if [[ $item == *"to-openshift-apiserver-service-cluster"* ]]; then
    echo "to-openshift-apiserver-service-cluster-NODE: $TCPERRORS"
  fi

  # to-kubernetes-apiserver-endpoint
# to-kubernetes-apiserver-service-cluster
# to-kubernetes-default-service-cluster
# to-load-balancer-api-external
# to-load-balancer-api-internal
# to-network-check-target-service-cluster
# to-network-check-target-  |grep -v service-cluster
# to-openshift-apiserver-endpoint
# to-openshift-apiserver-service-cluster

  num=$(($num+1))
done


num=1 
echo ""
echo ""
echo -e "-------------------"
echo -e "- ETCD ------------"
echo -e "-------------------"
echo ""
for item in `oc get pod -n openshift-etcd --no-headers |grep -v guard| grep -v revision|grep -v installer| awk '{print $1}'`
do
    echo "[ETCD POD $num]"
    num=$(($num+1))
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
    fi
    if (( $OVERDISK != 0 )); then
      echo "overloaded disk: $OVERDISK"
    fi
    if (( $CLOCKDIF != 0 )); then
      echo "clock difference: $CLOCKDIF"
    fi
    if (( $CLOCKDRIFT != 0 )); then
      echo "clock-drift: $CLOCKDRIFT"
    fi
    if (( $TOOKTOOLONG != 0 )); then
      echo "apply request took too long: $TOOKTOOLONG"
    fi
    if (( $DBSPACE != 0 )); then
      echo "database space exceeded: $DBSPACE"
    fi
    if (( $LEADERCHANGE != 0 )); then
      echo "leader changed: $LEADERCHANGE"
    fi
    echo -e ""
done
echo -e ""


num=1
echo ""
echo ""
echo -e "-------------------"
echo -e "- ROUTERS ---------"
echo -e "-------------------"
echo ""
for item in `oc get pod -n openshift-ingress --no-headers | awk '{print $1}'`
do
    echo "[ROUTER POD $num]"
    echo ""
    RWATCHCLOSE=$(oc logs -n openshift-ingress $item |grep 'Unexpected watch close'|wc -l)
    RERRSERVER=$(oc logs -n openshift-ingress $item |grep 'error on the server'|wc -l)
    RCTXDEADLINE=$(oc logs -n openshift-ingress $item |grep 'context deadline exceeded'|wc -l)
    RTIMEOUT=$(oc logs -n openshift-ingress $item |grep 'timeout'|wc -l)
    RPROC=$(oc logs -n openshift-ingress $item |grep 'process'|wc -l)
    RCLOCK=$(oc logs -n openshift-ingress $item |grep 'clock'|wc -l)
    RBUFFER=$(oc logs -n openshift-ingress $item |grep 'buffer'|wc -l)

    if (( $RWATCHCLOSE != 0 )); then
      echo "Unexpected watch close: $RWATCHCLOSE"
    fi
    if (( $RERRSERVER != 0 )); then
      echo "error on the server: $RERRSERVER"
    fi
    if (( $RCTXDEADLINE != 0 )); then
      echo "context deadline exceeded: $RCTXDEADLINE"
    fi
    if (( $RTIMEOUT != 0 )); then
      echo "timeout: $RTIMEOUT"
    fi
    if (( $RPROC != 0 )); then
      echo "process: $RPROC"
    fi
    if (( $RCLOCK != 0 )); then
      echo "clock: $RCLOCK"
    fi
    if (( $RBUFFER != 0 )); then
      echo "buffer: $RBUFFER"
    fi
    
    echo ""
    echo ""
    num=$(($num+1))
done

num=1
echo ""
echo ""
echo -e "-------------------"
echo -e "- APISERVER -------"
echo -e "-------------------"
echo ""


for item in `oc get pod -n openshift-kube-apiserver --no-headers|grep -i running | awk '{print $1}'`
do
    echo "[APISERVER POD $num]"
    echo ""
    TIMED=$(oc logs -n openshift-kube-apiserver $item |grep 'timed out'|wc -l)
    CTXDEAD=$(oc logs -n openshift-kube-apiserver $item |grep 'deadline exceeded'|wc -l)
    TIM=$(oc logs -n openshift-kube-apiserver $item  |grep 'timeout'|wc -l)
    PROCS=$(oc logs -n openshift-kube-apiserver $item  |grep 'process'|wc -l)
    CLK=$(oc logs -n openshift-kube-apiserver $item  |grep 'clock'|wc -l)
    BFFR=$(oc logs -n openshift-kube-apiserver $item  |grep 'buffer'|wc -l)

    if (( $TIMED != 0 )); then
      echo "Timed out: $TIMED"
    fi
    if (( $CTXDEAD != 0 )); then
      echo "deadline exceeded: $CTXDEAD"
    fi
    if (( $TIM != 0 )); then
      echo "timeout: $TIM"
    fi
    if (( $PROCS != 0 )); then
      echo "process: $PROCS"
    fi
    if (( $CLK != 0 )); then
      echo "clock: $CLK"
    fi
    if (( $BFFR != 0 )); then
      echo "buffer: $BFFR"
    fi

    echo ""
    echo ""
    num=$(($num+1))
done


num=1
echo ""
echo ""
echo -e "--------------------"
echo -e "- Network Operator -"
echo -e "--------------------"
echo ""
for item in `oc get pod -n openshift-network-operator --no-headers|grep -i running | awk '{print $1}'`
do
    CONTXT=$(oc logs -n openshift-network-operator $item |grep 'deadline exceeded'|wc -l)
    CLOCK=$(oc logs -n openshift-network-operator $item  |grep 'clock skew'|wc -l)
    FAILAPP=$(oc logs -n openshift-network-operator $item  |grep 'err: failed to apply'|wc -l)

    echo "[Network Operator POD $num]"
    echo ""
    if (( $CONTXT != 0 )); then
      echo "context deadline exceeded: $CONTXT"
    fi
    if (( $CLOCK != 0 )); then
      echo "clock skew: $CLOCK"
    fi
    if (( $FAILAPP != 0 )); then
      echo "failed to apply: $FAILAPP"
    fi
    
    # echo "context deadline exceeded: $(oc logs -n openshift-network-operator $item |grep 'deadline exceeded'|wc -l)"
    # echo "clock: $(oc logs -n openshift-network-operator $item  |grep 'clock skew'|wc -l)"    
    # echo "buffer: $(oc logs -n openshift-network-operator $item  |grep 'err: failed to apply'|wc -l)"   
    echo ""
    echo ""
    num=$(($num+1))
done











# num=1
# echo ""
# echo ""
# echo -e "-------------------"
# echo -e "- OVN -------------"
# echo -e "-------------------"
# echo ""
# for item in `oc get pod -n openshift-ovn-kubernetes --no-headers|grep node|grep -i running | awk '{print $1}'`
# do
#     echo "[OVN POD $num NORTHDB]"
#     echo ""
#     echo "Unreasonably long poll interval: $(oc logs -n openshift-ovn-kubernetes $item -c northd |grep 'Unreasonably long'|wc -l)"
#     echo "timeout at: $(oc logs -n openshift-ovn-kubernetes $item -c northd |grep 'timeout at'|wc -l)"    
#     echo "OVNNB/SB commit failed, force recompute next time: $(oc logs -n openshift-ovn-kubernetes $item -c northd |grep 'commit failed'|wc -l)"    
#     echo "no response to inactivity probe: $(oc logs -n openshift-ovn-kubernetes $item -c northd |grep 'no response to inactivity probe'|wc -l)"   
#     echo ""
#     echo ""
#     num=$(($num+1))
# done

# pods.go:40] Couldn't allocate IPs: 10.129.0.4 for pod: (overlapping PodIPs)
# addLogicalPort took 963.236483ms (very long addLogicalPort times)
# setup retry failed; will try again later (something failed in addLogicalPort)



num=1
echo -e "-------------------"
echo -e "- MachineConfig ---"
echo -e "-------------------"
echo ""
for node in $(oc get nodes -o name | awk -F'/' '{ print $2 }')
do
  echo "[NODE $num]"
  oc describe node $node | grep machineconfiguration.openshift.io/state
  num=$(($num+1))
done