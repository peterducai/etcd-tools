#!/bin/bash

. library.sh
. warnings.sh


MG_PATH="$1"

NODES=()
MASTER=()
INFRA=()
WORKER=()
OCS=()
ETCD=()


change_to_must_gather_dir () {
    echo "Changing to Must Gather directory... $MG_PATH"
    cd $MG_PATH
    cd $(ls -d quay* )
    FULL_PATH=$(pwd)
    echo ""
}

list_version () {
    echo -e "${GREEN}- Cluster Version ----------${NONE}"
    cat $FULL_PATH/version|tail -1
    echo ""
}

list_nodes () {
    # NODES
    cd $FULL_PATH/cluster-scoped-resources/core/nodes/
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
    
    for filename in *.yaml; do
        [ -e "$filename" ] || continue
        [ ! -z "$(cat $filename |grep -w 'cluster.ocs.openshift.io/openshift-storage')" ] && OCS+=("${filename::-5}")  || true
    done
    
    echo -e ""
    echo -e "${GREEN}- NODES --------------------${NONE}"
    echo -e ""
    
    
    # MASTERS / CONTROL PLANES
    
    echo -e "${#MASTER[@]} masters"
    echo -e "${#INFRA[@]} infra nodes"
    echo -e "${#WORKER[@]} worker nodes"
    echo -e "${#OCS[@]} ocs nodes"
    echo -e ""
}

network_cluster_scale () {
    echo -e "${GREEN}- Network Cluster Scale --------${NONE}"
    cat $FULL_PATH/network_logs/cluster_scale
    echo ""
}

etcd_object_count () {
    echo -e "${GREEN}- ETCD Object Count ------------${NONE}"
    jq . $FULL_PATH/etcd_info/object_count.json |head -10|tail -n +2
    echo ""
}

list_monitoring () {
    echo -e "${GREEN}- Monitoring Configuration -----${NONE}"
    jq . $FULL_PATH/monitoring/prometheus/status/flags.json |grep retention.size
    jq . $FULL_PATH/monitoring/prometheus/status/flags.json |grep retention.time
    jq . $FULL_PATH/monitoring/prometheus/status/flags.json |grep timeout
    echo ""
}


network_check_routers () {
    echo -e "${GREEN}- Network Check: Routers --------${NONE}"
    echo ""
    cd $FULL_PATH/namespaces/openshift-ingress/pods
    for router in $(ls -d */); do
        echo -e "- ${GREEN}$router${NONE}"
        echo "" > $router.log
        WATCH=$(cat $router/router/router/logs/current.log |grep 'Unexpected watch close'|wc -l)
        RERR=$(cat $router/router/router/logs/current.log |grep 'error on the server'|wc -l)
        DEAD=$(cat $router/router/router/logs/current.log |grep 'context deadline exceeded'|wc -l)
        CLTIME=$(cat $router/router/router/logs/current.log |grep 'timeout'|wc -l)
        
        PRC=$(cat $router/router/router/logs/current.log |grep 'process'|wc -l)
        CLK=$(cat $router/router/router/logs/current.log |grep 'clock'|wc -l)
        BFR=$(cat $router/router/router/logs/current.log |grep 'buffer'|wc -l)
        
        echo -e "" > $router.log
        echo "Unexpected watch close $WATCH"
        echo "error on the server $RERR"
        echo "context deadline exceeded $DEAD"
        echo "timeout $CLTIME"
        echo "process $PRC"
        echo "clock $CLK"
        echo "buffer $BFR"
    done
    echo ""
}

change_to_must_gather_dir
list_version
list_nodes
network_cluster_scale
etcd_object_count
list_monitoring
network_check_routers