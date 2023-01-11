#!/bin/bash


#kubectl get nodes -l node-role.kubernetes.io/master=
#$ kubectl get nodes -l node-role.kubernetes.io/master= -o template --template='{{range .items}}{{"===> node:> "}}{{.metadata.name}}{{"\n"}}{{range $k, $v := .metadata.annotations}}{{println $k ":" $v}}{{end}}{{"\n"}}{{end}}'

kubectl exec -c etcdctl -n openshift-etcd $(kubectl get po -l app=etcd -oname -n openshift-etcd | awk -F"/" 'NR==1{ print $2 }') etcdctl endpoint health -w table



# histogram_quantile(0.99, sum by (instance, le) (irate(etcd_disk_wal_fsync_duration_seconds_bucket{job="etcd"}[5m])))

echo -e "etcdGRPCRequestsSlow"
histogram_quantile(0.99, sum(rate(grpc_server_handling_seconds_bucket{job=~".*etcd.*", grpc_type="unary"}[5m])) without(grpc_type))
histogram_quantile(0.99, sum by (instance, le) (irate(etcd_disk_wal_fsync_duration_seconds_bucket{job="etcd"}[5m])))


#PromQL query is the following to see top consumers of CPU:

      topk(25, sort_desc(
        sum by (namespace) (
          (
            sum(avg_over_time(pod:container_cpu_usage:sum{container="",pod!=""}[5m])) BY (namespace, pod)
            *
            on(pod,namespace) group_left(node) (node_namespace_pod:kube_pod_info:)
          )
          *
          on(node) group_left(role) (max by (node) (kube_node_role{role=~".+"}))
        )
      ))