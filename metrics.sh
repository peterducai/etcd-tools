#!/bin/bash

################################################################################
#                     Metrics collector                                        #
#                                                                              #
# Script to collect metrics from ETCD                                          #
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
token=$(oc whoami -t)

ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA
mkdir -p $OUTPUT_PATH/metrics

host=$(oc -n openshift-monitoring get route prometheus-k8s -ojsonpath={.spec.host})
thanos=$(oc -n openshift-monitoring get route thanos-querier -ojsonpath={.spec.host})
period="3d"

prom_query() {
    #oc exec -c prometheus -n openshift-monitoring thanos-querier -- curl http://$thanos/api/v1/query --data-urlencode $@ 
    curl -kgs -H "Authorization: Bearer $token" \
     "https://$thanos/api/v1/query" \
     --data-urlencode $@ 
}

analytics() {
    echo -e "Get etcd failure rate in the last $period"
    #prom_query "query=rate(etcd_network_peer_sent_failures_total{job=~\".*etcd.*\"}[3m])"
    #prom_query "query=rate(etcd_network_peer_sent_failures_total{job=~\".*etcd.*\"}[30m])" #> etcd_failure_rate_3m
    prom_query "query=histogram_quantile(0.99, irate(etcd_disk_wal_fsync_duration_seconds_bucket[5m]))"
    #period="3d"
    echo -e "node_cpu_utilisation"
    prom_query "query=instance:node_cpu_utilisation:rate1m[3d]"
    #echo -e ""
    #echo -e "node_disk_io_time_seconds"
    #prom_query "query=instance_device:node_disk_io_time_seconds:rate1m[$period]"
}

failures()  {
    echo -e "node_cpu_utilisation"
    prom_query "query=instance:node_cpu_utilisation:rate1m[$period]"  > $OUTPUT_PATH/metrics/cpu_utilization
    echo -e ""
    echo -e "node_disk_io_time_seconds"
    prom_query "query=instance_device:node_disk_io_time_seconds:rate1m[$period]"  > $OUTPUT_PATH/metrics/disk_io
    echo -e ""
    echo -e "container_fs_writes_bytes_total"
    prom_query "query=rate(container_fs_writes_bytes_total{pod=\"$pod\"}[$period])"  > $OUTPUT_PATH/metrics/container_fs_writes_bytes_total
    prom_query "query=rate(container_fs_reads_bytes_total{pod=\"$pod\"}[$period])"  > $OUTPUT_PATH/metrics/container_fs_reads_bytes_total
}

failures
#analytics
