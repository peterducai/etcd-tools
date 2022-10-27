#!/bin/bash


#images used by pods
oc get pods -A -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq

#imagestreams referencing images
oc get imagestream -A -o jsonpath="{..dockerImageReference}" | tr -s '[[:space:]]' '\n' | sort | uniq|wc -l


oc get replicasets -A |grep  -E '0{1}\s+0{1}\s+0{1}'|wc -l
oc get replicasets -A |grep  -E '0{1}\s+0{1}\s+0{1}'| awk '{print "-n " $1, $2}'
#oc get replicasets -A |grep  -E '0{1}\s+0{1}\s+0{1}'| awk '{print "oc delete replicaset -n " $1, $2}' | sh


oc get deployments -A |grep  -E '0{1}/[0-9]+'


oc get jobs -A|wc -l


oc get deployment -A|awk '{print $2 " -n " $1}'

oc describe deployment alpine -n foo|grep Image | awk '{print $2}'



oc get deployment -A|awk '{print $2" -n "$1}'|tail -n +2 > deployment.log
while IFS= read -r line; do oc describe deployment $line |grep Image | awk '{print $2}'; done < deployment.log
while IFS= read -r line; do oc describe deployment $line |grep Image | awk '{print $2}'; done < deployment.log |wc -l



oc get is -A | awk '{print $2}'