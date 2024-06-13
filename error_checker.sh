#!/bin/bash

echo -e "connect: network is unreachable"
cat $1 |grep "connect: network is unreachable"|wc -l
echo -e ""
echo -e "Failed to open cgroups"
cat $1 |grep "Failed to open cgroups"|wc -l
echo -e ""
echo -e "PLEG is not healthy"
cat $1 |grep "PLEG is not healthy"|wc -l
echo -e ""
echo -e "exited with status 255"
cat $1 |grep "exited with status 255"|wc -l
echo -e ""
echo -e "exited with status 1"
cat $1 |grep "exited with status 1"|wc -l
echo -e ""
echo -e "exited with status 2"
cat $1 |grep "exited with status 2"|wc -l
echo -e ""
echo -e "PullImage from image service failed"
cat $1 |grep "PullImage from image service failed"|sort |uniq|wc -l
echo -e ""
echo -e "No CNI configuration file in"
cat $1 |grep "No CNI configuration file in"|sort |uniq|wc -l
echo -e ""
echo -e "Error getting ContainerStatus for containerID"
cat $1 |grep "Error getting ContainerStatus for containerID"|sort |uniq|wc -l
echo -e ""
echo -e "network is not ready: container runtime network not ready"
cat $1 |grep "network is not ready: container runtime network not ready"|sort |uniq|wc -l
echo -e ""
echo -e "can't find the container with id"
cat $1 |grep "can't find the container with id"|sort |uniq|wc -l
echo -e ""
echo -e "DeleteContainer returned error"
cat $1 |grep "DeleteContainer returned error"|sort |uniq|wc -l
echo -e ""
echo -e "timeout"
cat $1 |grep "timeout"|sort |uniq|wc -l
echo -e ""
echo -e "failed to connect service"
cat $1 |grep "failed to connect service"|sort |uniq|wc -l
echo -e ""
echo -e "Connection reset by peer"
cat $1 |grep "Connection reset by peer"|sort |uniq|wc -l
echo -e ""
echo -e "Layer4 timeout"
cat $1 |grep "Connection reset by peer"|sort |uniq|wc -l
echo -e ""

