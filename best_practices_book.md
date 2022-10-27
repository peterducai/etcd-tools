# Best practices for Openshift


## Namespaces

By default, there are 3 namespaces in a K8s cluster, default, kube-public and kube-system and additionaly openshift-* namespaces in OCP4.


## Readiness and Liveness Probes

## Resource Requests and Limits

Resource requests and limits (minimum and maximum amount of resources that can be used in a container) should be set to avoid a container starting without the required resources assigned, or the cluster running out of available resources.