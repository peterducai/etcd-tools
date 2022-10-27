#!/bin/bash

echo -e "DRY RUN without paramateters"
echo -e "Depending on the size of cluster, this script can run from several seconds to several minutes."
echo -e "This test doesn't count openshift-release-dev images."
echo -e ""

MUST_PATH=$1
ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA

#rm -rf $OUTPUT_PATH
mkdir -p $OUTPUT_PATH

# PARSER --------------------------------------------------------------------------

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -a|--my-boolean-flag)
      MY_FLAG=0
      shift
      ;;
    -b|--my-flag-with-argument)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        MY_FLAG_ARG=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

#---------------------------------------------------------------------------------




#imagestreams referencing images
oc get imagestream -A -o jsonpath="{..dockerImageReference}" | tr -s '[[:space:]]' '\n' |grep -v 'openshift-release-dev' | sort | uniq > $OUTPUT_PATH/is_images.log
oc get is -A > $OUTPUT_PATH/is.log

echo -e "IMAGESTREAM: there is $(cat $OUTPUT_PATH/is_images.log|grep -v 'openshift-release-dev'|wc -l) images referenced by Imagestreams."
echo -e "..."
#images used by pods
oc get pods -A -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n'|grep -v 'openshift-release-dev' | sort | uniq  > $OUTPUT_PATH/pod_images.log
echo -e "PODS: there is $(cat $OUTPUT_PATH/pod_images.log|grep -v 'openshift-release-dev'|wc -l) images referenced by pods."

#replicasets

# oc get replicasets -A |grep  -E '0{1}\s+0{1}\s+0{1}'|wc -l
oc get replicasets -A |grep  -E '0{1}\s+0{1}\s+0{1}'| awk '{print "-n " $1, $2}'|sort|uniq > $OUTPUT_PATH/replicasets.log
#oc get replicasets -A |grep  -E '0{1}\s+0{1}\s+0{1}'| awk '{print "oc delete replicaset -n " $1, $2}' | sh
echo -e "REPLICASET: there is $(cat $OUTPUT_PATH/replicasets.log|grep -v 'openshift-release-dev'|wc -l) images referenced by ReplicaSets."

# oc get deployments -A |grep  -E '0{1}/[0-9]+'  > $OUTPUT_PATH/deployments.log


oc get jobs -A|wc -l > $OUTPUT_PATH/jobs.log


# oc get deployment -A|awk '{print $2 " -n " $1}'

# oc describe deployment alpine -n foo|grep Image | awk '{print $2}'



oc get deployment -A|tail -n +2 > $OUTPUT_PATH/deployment.log
cat $OUTPUT_PATH/deployment.log |awk '{print $2" -n "$1}' > $OUTPUT_PATH/deploy.log
# while IFS= read -r line; do oc describe deployment $line |grep Image | awk '{print $2}'; done < deployment.log

oc get deployment -A -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq > $OUTPUT_PATH/depimage.log
# while IFS= read -r line; do oc describe deployment $line |grep Image | awk '{print $2}'; done < $OUTPUT_PATH/deploy.log > $OUTPUT_PATH/depimage.log
# sort $OUTPUT_PATH/depimage.log |uniq|wc -l
# echo -e "DEPLOYMENT: there is $(cat $OUTPUT_PATH/depimage.log|sort|uniq|wc -l) images referenced by Deployments."
echo -e "DEPLOYMENT: there is $(cat $OUTPUT_PATH/depimage.log|sort|uniq|grep -v 'openshift-release-dev'|wc -l) images referenced by Deployments."



# oc get is -A | awk '{print $2}'


# Print images not used by any pod

#awk 'NR == FNR{ a[$0] = 1;next } !a[$0]' pod_images.log is_images.log

# Print images not used by any Deployment

#awk 'NR == FNR{ a[$0] = 1;next } !a[$0]' deploy.log is_images.log