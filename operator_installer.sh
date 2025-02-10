#!/bin/bash



oc get packagemanifests|grep 'Red Hat'|awk ' { print $1 } '



oc get packagemanifests $opname -o jsonpath="{range .status.channels[*]}Channel: {.name} currentCSV: {.currentCSV}{'\n'}{end}"











pducai@fedora:~$ oc get packagemanifests nfd -o jsonpath="{range .status.channels[*]}Channel: {.name} currentCSV: {.currentCSV}{'\n'}{end}"
Channel: stable current CSV: nfd.4.16.0-202501271512



pducai@fedora:~$ oc get packagemanifests nfd -o jsonpath={.status.catalogSource}
redhat-operators




oc get packagemanifests nfd -o jsonpath={.status.catalogSourceNamespace}SourceNamespace}
openshift-marketplace

