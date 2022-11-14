#!/bin/bash

# Variable definition
# COUNT: number of events deleted per requests. 
# FROM: first event in etcd
# TO: last event to delete in the query
# NUM: number of events deleted

COUNT=10000













echo -e ""
echo -e "[Delete events]"
echo -e ""

FROM="$(etcdctl --command-timeout=60s get '/kubernetes.io/events/' --prefix --keys-only --limit 1)"
while :; do
  TO="$(etcdctl get '/kubernetes.io/events/' --command-timeout=60s --prefix --keys-only --limit ${COUNT} | sed '/^$/d' | tail -1)"
  [ $(etcdctl get ${FROM} ${TO} --command-timeout=60s --keys-only | grep -vEc "^$|^/kubernetes.io/events/") -eq 0 ] && NUM=$(etcdctl --command-timeout=60s del ${FROM} ${TO}) || { echo "Non event key found, aborting..." ; break ;}
  [ "${NUM}" == "0" ] && echo "All events deleted" && break
  echo "${NUM} events deleted"
done