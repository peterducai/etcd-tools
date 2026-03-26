#!/bin/bash


echo -e "Masters: $(omc get node|grep master|wc -l)"
echo -e "Infras: $(omc get node|grep infra|wc -l)"
echo -e "Workers: $(omc get node|grep worker|wc -l)"
echo -e ""
echo -e "ALL PODS: $(omc get pod -A|wc -l)"
echo -e "CrashLoopBackOff PODS: $(omc get pod -A|grep -i CrashLoopBackOff|wc -l)"
omc get pod -A|grep -i CrashLoopBackOff|sort -k5 -r|head -10
echo -e "ERROR PODS: $(omc get pod -A|grep -i error|wc -l)"
omc get pod -A|grep -i error|sort -k5 -r|head -10
echo -e ""
echo -e "MOST RESTARTS:"
omc get pod -A|grep -i running|sort -k5 -r|head -10
echo -e ""
echo -e "NUMBER OF PVs: $(omc get pv -A|wc -l)"
echo -e "NUMBER OF PVCs: $(omc get pvc -A|wc -l)"
echo -e ""
echo -e "Mutatingwebhookconfigurations: $(omc get mutatingwebhookconfigurations|wc -l)"
echo -e "Biggest ones:"
omc get mutatingwebhookconfigurations|sort -k2 -r|head -10
echo -e ""
echo -e "Validatingwebhookconfigurations: $(omc get validatingwebhookconfigurations|wc -l)"
echo -e "Biggest ones:"
omc get validatingwebhookconfigurations |sort -k2 -r|head -10
