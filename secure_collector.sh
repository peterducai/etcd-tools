#!/bin/bash 

WARNINGS=(
    'apply request took too long'
    'leader changed'
    'failed to send out heartbeat on time'
    'overloaded likely from slow disk'
    # 'clock difference'
    # 'Clock not synchronising'
    'clock skew'
    'process'
    'buffer'
    'unexpected watch close'
    'context deadline exceeded'
    'error on the server'
    'timeout'
    'failed'
    'forbidden'
    # 'driver not found'
    'failed to get'
    'failed to download'
    'failed to retrieve a role for a rolebinding'
    'Failed to find app'
)

cd $1

for str in "${WARNINGS[@]}"; do
  FILEARR=()
  echo -e ""
  echo -e "[$str] -----------------"
  echo -e ""
  # grep -cinR "$str" | grep -v ':0$' |sort -t':' -n -k2 | tac |head -10
  FILEARR=$(grep -cinR "$str" | grep -v ':0$'| grep ".log:"| sort -t':' -n -k2 | tac|head -10)                         #| grep -E -o ":[[:digit:]]+" 
  readarray -t FIL <<< $FILEARR
  for i in "${FIL[@]}"
  do
    j=${i%:*}
    LASTSEEN=$(cat $j |grep "$str" |tail -1| head -c 10)
    echo -e "$i  last seen on $LASTSEEN"
  done
  echo -e ""  
done