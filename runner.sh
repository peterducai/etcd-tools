#!/bin/bash

case "$1" in
  etcd)
    ./etcd-mg.sh $2 $3
    ;;
  toolong)
    etcd_tooktoolong.py $2
    ;;
  fio)
    ./fio_suite.sh
    ;;
  full)
    ./iostat.sh &
    ./top.sh &
    sleep 1
    ./fio_suite2.sh &  > fio.log
    wait
    echo "All tests are complete"
    echo -e ""
    echo -e "RESULTS:"
    cat top.log
    echo -e ""
    cat iostat.log
    echo -e ""
    cat r70_w30_1G_d4.log
    echo -e ""
    cat r70_w30_200M_d4.log
    echo -e ""
    cat r30_w70_200M_d1.log
    echo -e ""
    cat r30_w70_1G_d1.log
    echo -e ""
    cat r70_w30_1G_d4.log
    echo -e ""
    cat r30_w70_200M_d1.log
    echo -e ""
    cat r30_w70_1G_d1.log
    #
    rm r70_w30_1G_d4.log
    rm r70_w30_200M_d4.log
    rm r30_w70_200M_d1.log
    rm r30_w70_1G_d1.log
    rm r70_w30_1G_d4.log
    rm r30_w70_200M_d1.log
    rm r30_w70_1G_d1.log
    ;;
  *)
    echo -e "NO PARAMS. Choose 'etcd' or 'fio' or 'toolong'"
    ;;
esac