#!/bin/bash

################################################################################
#                            Cleanup Analyzer                                  #
#                                                                              #
# Script to analyze which Deployments, Images and ReplicaSets could be         #
# cleaned up and to generate cleanup scripts.                                  #
#                                                                              #
#                                                                              #
################################################################################
################################################################################
################################################################################
#                                                                              #
#  Copyright (C) 2022 Peter Ducai                                              #
#  peter.ducai@gmail.com                                                       #
#  pducai@icloud.com                                                           #
#                                                                              #
#  This program is free software; you can redistribute it and/or modify        #
#  it under the terms of the GNU General Public License as published by        #
#  the Free Software Foundation; either version 2 of the License, or           #
#  (at your option) any later version.                                         #
#                                                                              #
#  This program is distributed in the hope that it will be useful,             #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of              #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
#  GNU General Public License for more details.                                #
#                                                                              #
#  You should have received a copy of the GNU General Public License           #
#  along with this program; if not, write to the Free Software                 #
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA   #
#                                                                              #
################################################################################
################################################################################
################################################################################


STAMP=$(date +%Y-%m-%d_%H-%M-%S)
CLIENT="oc"
MUST_PATH=$1
ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA
OLDER_THAN=30

#rm -rf $OUTPUT_PATH
mkdir -p $OUTPUT_PATH


PARAMS=""
while (( "$#" )); do
  case "$1" in
    -f|--force)
      FORCE_DELETION=0
      shift
      ;;
    -k|--kubectl)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        CLIENT="kubectl"
        ETCD_NS="kube-system"
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -o|--olderthan)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        OLDER_THAN=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      print_help
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

# FUNCTIONS

print_help() {
  echo -e "Depending on the size of cluster, this script can run from several seconds to several minutes."
  echo -e ""
  echo -e $STAMP
  echo -e "SUMMARY:"
  echo -e ""
  echo -e "HELP:"
  # echo -e "-f | --force : to actually delete ReplicaSets not in use. (Not implemented)"
  # echo -e "-g | --graph : graph referenced images. (Not implemented)"
  echo -e "-o | --olderthan : print all unused deployments and replicasets, older than X days"
  echo -e ""
}

namespaces() {
  echo -e ""
  echo -e "[NAMESPACES]--------------------------------"
  oc get ns |grep -v openshift|grep -v kube|grep -v default > $OUTPUT_PATH/ns.log
  oc get ns > $OUTPUT_PATH/ns_all.log
  echo -e ""
  echo -e "$(cat $OUTPUT_PATH/ns.log|wc -l) non-openshift namespaces."
  echo -e "$(cat $OUTPUT_PATH/ns_all.log|wc -l) namespaces together."
}

imagestreams() {
  echo -e ""
  echo -e "[IMAGESTREAMS]--------------------------------"
  $CLIENT get imagestream -A -o jsonpath="{..dockerImageReference}" | tr -s '[[:space:]]' '\n'| sort | uniq > $OUTPUT_PATH/is_images.log
  $CLIENT get is -A > $OUTPUT_PATH/is.log
  ISALL=$(cat $OUTPUT_PATH/is_images.log|uniq|wc -l)
  ISDEV=$(cat $OUTPUT_PATH/is_images.log|uniq|grep openshift-release-dev|wc -l)
  echo -e ""
  echo -e "$ISALL images referenced by Imagestreams."
  echo -e "$ISDEV openshift-release-dev images referenced by Imagestreams."
  echo -e "$(("$ISALL"-"$ISDEV")) other images referenced by Imagestreams."
  echo -e ""
  cat $OUTPUT_PATH/is_images.log |cut -d/ -f1,2|sort -k1,2|uniq -c|sort -n --rev|head -10

}

imagestreamtags() {
  echo -e ""
  echo -e "[IMAGESTREAMTAGS]--------------------------------"
  $CLIENT get imagestream -A -o jsonpath="{.output.to.name}" | tr -s '[[:space:]]' '\n'| sort | uniq > $OUTPUT_PATH/is_images.log
  $CLIENT get is -A > $OUTPUT_PATH/is.log
  ISALL=$(cat $OUTPUT_PATH/is_images.log|uniq|wc -l)
  ISDEV=$(cat $OUTPUT_PATH/is_images.log|uniq|grep openshift-release-dev|wc -l)
  echo -e "IMAGESTREAMTAGS: there are $ISALL images referenced by Imagestreamtags."
  echo -e "IMAGESTREAMTAGS: there are $ISDEV openshift-release-dev images referenced by Imagestreamtags."
  echo -e "IMAGESTREAMTAGS: there are $(("$ISALL"-"$ISDEV")) other images referenced by Imagestreamtags."
  echo -e "..."
  cat $OUTPUT_PATH/is_images.log |cut -d/ -f1,2|sort -k1,2|uniq -c|sort -n --rev|head -10

}


pods() {
  echo -e ""
  echo -e "[PODS]--------------------------------"
  echo -e ""
  $CLIENT get pods -A|tail -n +2 > $OUTPUT_PATH/pod.log
  echo -e "$(cat $OUTPUT_PATH/pod.log|wc -l) pods together."
  $CLIENT get pods -A -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n'| sort | uniq  > $OUTPUT_PATH/pod_images.log
  echo -e "$(cat $OUTPUT_PATH/pod_images.log|wc -l) images referenced by pods."
  echo -e ""
  cat $OUTPUT_PATH/pod_images.log |cut -d/ -f1,2|sort -k1,2|uniq -c|sort -n --rev|head -10
}

# REPLICASETS

replicasets() {
  echo -e ""
  echo -e "[REPLICASETS]--------------------------------"
  echo -e ""
  $CLIENT get replicasets -A > $OUTPUT_PATH/rs.log
  cat $OUTPUT_PATH/rs.log |grep  -E '0{1}\s+0{1}\s+0{1}'| awk -v OLDER_THAN=$OLDER_THAN '($6*3600) > ( OLDER_THAN * 3600) {print $1, $2, $6 }'|sort -k 3n|uniq > $OUTPUT_PATH/rs_inactiv.log
  cat $OUTPUT_PATH/rs_inactiv.log|grep -v openshift|awk -v OLDER_THAN=$OLDER_THAN '($3*3600) > ( OLDER_THAN*3600 ) {print "oc delete rs -n " $1, $2 }' > $OUTPUT_PATH/older_than_${OLDER_THAN}days.sh
  cat $OUTPUT_PATH/rs_inactiv.log|grep openshift|awk -v OLDER_THAN=$OLDER_THAN '($3*3600) > ( OLDER_THAN*3600 ) {print "oc delete rs -n " $1, $2 }' > $OUTPUT_PATH/older_ocp_than_${OLDER_THAN}days.sh
  #cat $OUTPUT_PATH/rs.log |grep  -E '0{1}\s+0{1}\s+0{1}'| awk '{print "-n " $1, $2}'|sort|uniq > $OUTPUT_PATH/rs_inactive.log
  #cat rs.log |grep  -E '0{1}\s+0{1}\s+0{1}'| awk '{print "oc describe rs -n " $1, $2, $6, ($6*3600) }'|sort -k 7n|uniq
  $CLIENT get rs -A  -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq > $OUTPUT_PATH/rs_images.log
  $CLIENT get replicasets -A | awk '{print "-n " $1, $2}'|sort|uniq > $OUTPUT_PATH/replicasetsns.log
  echo -e "$(cat $OUTPUT_PATH/rs.log|wc -l) ReplicaSets."
  echo -e "$(cat $OUTPUT_PATH/rs_inactiv.log|wc -l) INACTIVE ReplicaSets."
  echo -e "$(cat $OUTPUT_PATH/rs_inactiv.log|grep 'openshift-'|wc -l) INACTIVE openshift-* ReplicaSets."
  echo -e "$(cat $OUTPUT_PATH/rs_inactiv.log|grep -v 'openshift-'|wc -l) INACTIVE non OCP ReplicaSets."
  echo -e "$(cat $OUTPUT_PATH/rs_images.log|wc -l) images referenced by ReplicaSets."
  echo -e ""
  echo -e "$(cat $OUTPUT_PATH/rs_inactiv.log|wc -l) replicasets older than $OLDER_THAN days"
  echo -e "All inactive non-openshift/user RS are written to $OUTPUT_PATH/older_than_${OLDER_THAN}days.sh"
  echo -e "All inactive openshift- RS are written to $OUTPUT_PATH/older_ocp_than_${OLDER_THAN}days.sh"
  echo -e ""
  cat $OUTPUT_PATH/rs_images.log |cut -d/ -f1,2|sort -k1,2|uniq -c|sort -n --rev|head -10
  # cat $OUTPUT_PATH/rs.log |grep  -E '0{1}\s+0{1}\s+0{1}'| awk '($6*3600) > (20*3600) {print "oc describe rs -n " $1, $2, $6 }'|sort -k 7n|uniq
}

deployments() {
  echo -e ""
  echo -e "[DEPLOYMENTS]--------------------------------"
  echo -e ""
  $CLIENT get deployment -A|tail -n +2 > $OUTPUT_PATH/deployment.log
  echo -e "$(cat $OUTPUT_PATH/deployment.log|wc -l) deployments."
  cat $OUTPUT_PATH/deployment.log |grep  -E '0{1}\s+0{1}\s'| awk -v OLDER_THAN=$OLDER_THAN '($6*3600) > ( OLDER_THAN * 3600) {print " " $1, $2, $6 }'|sort -k 3n|uniq > $OUTPUT_PATH/dep_inactiv.log
  cat $OUTPUT_PATH/deployment.log |awk '{print $2" -n "$1}' > $OUTPUT_PATH/deploy.log

  $CLIENT get deployment -A -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq > $OUTPUT_PATH/depimage.log
  echo -e "$(cat $OUTPUT_PATH/depimage.log|sort|uniq|wc -l) images referenced by Deployments."
  
  echo -e ""
  echo -e "$(cat $OUTPUT_PATH/dep_inactiv.log|wc -l) inactive deployments older than $OLDER_THAN days"
  echo -e ""
  cat $OUTPUT_PATH/dep_inactiv.log|cut -d/ -f1,2|sort -k1,2|uniq -c|sort -n --rev|head -10
}

buildconfigs() {
  echo -e ""
  echo -e "[BUILDCONFIGS]--------------------------------"
  echo -e ""
  $CLIENT get buildconfig -A -o jsonpath='{range .items[*].spec.output.to}{"\n"}{.name}' | tr -s '[[:space:]]' '\n'| sort | uniq > $OUTPUT_PATH/bc_images.log
  $CLIENT get bc -A > $OUTPUT_PATH/bc.log
  BCALL=$(cat $OUTPUT_PATH/bc_images.log|uniq|wc -l)
  BCDEV=$(cat $OUTPUT_PATH/bc_images.log|uniq|grep openshift-release-dev|wc -l)
  echo -e "$BCALL images referenced by BuildConfigs."
  echo -e "$BCDEV openshift-release-dev images referenced by BuildConfigs."
  echo -e "$(("$BCALL"-"$BCDEV")) non-openshift images referenced by BuildConfigs."
  echo -e ""
  cat $OUTPUT_PATH/bc_images.log |cut -d/ -f1,2|sort -k1,2|uniq -c|sort -n --rev|head -10
}


#NEW
xbuildconfigs() {
  echo -e ""
  echo -e "[IMAGESTREAMS]--------------------------------"
  $CLIENT get bc -A -o jsonpath="{..dockerImageReference}" | tr -s '[[:space:]]' '\n'| sort | uniq > $OUTPUT_PATH/is_images.log
  $CLIENT get bc -A > $OUTPUT_PATH/is.log
  ISALL=$(cat $OUTPUT_PATH/is_images.log|uniq|wc -l)
  ISDEV=$(cat $OUTPUT_PATH/is_images.log|uniq|grep openshift-release-dev|wc -l)
  echo -e "IMAGESTREAM: there are $ISALL images referenced by Imagestreams."
  echo -e "IMAGESTREAM: there are $ISDEV openshift-release-dev images referenced by Imagestreams."
  echo -e "IMAGESTREAM: there are $(("$ISALL"-"$ISDEV")) other images referenced by Imagestreams."
  echo -e "..."
  cat $OUTPUT_PATH/is_images.log |cut -d/ -f1,2|sort -k1,2|uniq -c|sort -n --rev|head -10

}


jobs() {
  echo -e ""
  echo -e "[JOBS]"
  $CLIENT get jobs -A|tail -n +2 > $OUTPUT_PATH/jobs.log
  echo -e "JOBS: there are $(cat $OUTPUT_PATH/jobs.log|wc -l) jobs."
}

delete_rs() {
  $CLIENT delete rs $1
}

list_all() {
  echo -e ""
  echo -e "DEPLOYMENT LIST:"
  echo -e "------------------------------------------------"
  echo -e "$(cat $OUTPUT_PATH/dep_inactiv.log)"
  echo -e ""
  echo -e ""
  echo -e "RS LIST:"
  echo -e "------------------------------------------------"
  echo -e "$(cat $OUTPUT_PATH/rs_inactiv.log)"
  echo -e ""
}

diffing() {
  # echo -e "diffing.."
  # Print images not used by any pod
  
  awk 'NR == FNR{ a[$0] = 1;next } !a[$0]' $OUTPUT_PATH/pod_images.log $OUTPUT_PATH/is_images.log > $OUTPUT_PATH/podis.log
  
  # Print images not used by any Deployment
  
  awk 'NR == FNR{ a[$0] = 1;next } !a[$0]' $OUTPUT_PATH/deploy.log $OUTPUT_PATH/is_images.log > $OUTPUT_PATH/depis.log
  awk 'NR == FNR{ a[$0] = 1;next } !a[$0]' $OUTPUT_PATH/depis.log $OUTPUT_PATH/podis.log > $OUTPUT_PATH/EXCESS.log
}

# MAIN

print_help
namespaces
imagestreams
pods
deployments
buildconfigs
replicasets
jobs
#list_all
diffing

echo -e ""
echo -e "[END]"




#oc get deploy -A -o jsonpath='{range .items[*]}{.metadata.name} revision:{.metadata.annotations.deployment\.kubernetes\.io\/revision}{"\n"}  {end}'