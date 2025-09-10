#!/bin/bash 

# run with
# >  ./secure_collector.sh <path to folder>

WARNINGS=(
    'apply request took too long'
    'Failed calling webhook'
    'denied the request'
    'leader changed'
    'failed to send out heartbeat on time'
    'overloaded likely from slow disk'
    'clock difference'
    'Clock not synchronising'
    'clock skew'
    'process'
    'defunct'
    'Pod in terminal state (e.g. completed) will be ignored as it has already been processed'
    'in terminal state (e.g. completed) during update event: will remove it'
    'dropped internal Raft message since sending buffer is full (overloaded network)'
    # 'buffer'
    'unexpected watch close'
    'context deadline exceeded'
    'error on the server'
    'timeout'
    'Unreasonably long'
    'ADD finished CNI request: err'
    'CNI request failed with'
    'Couldn't allocate IPs'
    'setup retry failed'
    'no response to inactivity probe after'
    #'failed'
    'could not get link modes: netlink receive: operation not supported'
    'tls: failed to verify certificate'
    'failed to list'
    'forbidden'
    'driver not found'
    'failed to get'
    'failed to download'
    'failed to retrieve a role for a rolebinding'
    'Failed to find app'
    'CNI request failed with status'
    'Housekeeping took longer than expected'
    'due to excessive rate'
    'iptables ChainExists'
    'KubeletNotReady'
    'Node became not ready'
    'client connection lost'
    'error adding container to network'
)

cd $1

# ALLFILES=$(tree -fi|grep ".log$"| cut -c 2-)
# for i in "${ALLFILES[@]}"; do
#   echo -e "$i"
# done

# exit

for str in "${WARNINGS[@]}"; do
  FILEARR=()
  echo -e ""
  echo -e "[$str] -----------------"
  echo -e ""
  # grep -cinR "$str" | grep -v ':0$' |sort -t':' -n -k2 | tac |head -10
  #FILEARR=$(grep -cinR "$str" | grep -v ':0$'| grep ".log:"| sort -t':' -n -k2 | tac|head -10)                        
  #| grep -E -o ":[[:digit:]]+" 
  ALLFILES=$(tree -fi|grep ".log$"| cut -c 2-)
  for i in "${ALLFILES[@]}"
  do
    #echo "processing $i"
    # j=${i%:*}
    # LASTSEEN=$(cat $j |grep "$str" |tail -1| head -c 10)
    # echo -e "$i  last seen on $LASTSEEN"
    grep -cinR "$str" | grep -v ':0$'| sort -t':' -n -k2 | tac|head -10
  done
  echo -e ""  
done