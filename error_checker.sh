#!/bin/bash

echo -e "connect: network is unreachable"
grep -Rh "connect: network is unreachable" $1 | wc -l
echo -e ""
echo -e "Failed to open cgroups"
grep -Rh "Failed to open cgroups" $1 | wc -l
echo -e ""
echo -e "PLEG is not healthy"
grep -Rh "PLEG is not healthy" $1 | wc -l
echo -e ""
echo -e "exited with status 255"
grep -Rh "exited with status 255" $1 | wc -l
echo -e ""
echo -e "exited with status 1"
grep -Rh "exited with status 1" $1 | wc -l
echo -e ""
echo -e "exited with status 2"
grep -Rh "exited with status 2" $1 | wc -l
echo -e ""
echo -e "PullImage from image service failed"
grep -Rh "PullImage from image service failed" $1 | sort | uniq | wc -l
echo -e ""
echo -e "No CNI configuration file in"
grep -Rh "No CNI configuration file in" $1 | sort | uniq | wc -l
echo -e ""
echo -e "Error getting ContainerStatus for containerID"
grep -Rh "Error getting ContainerStatus for containerID" $1 | sort | uniq | wc -l
echo -e ""
echo -e "network is not ready: container runtime network not ready"
grep -Rh "network is not ready: container runtime network not ready" $1 | sort | uniq | wc -l
echo -e ""
echo -e "can't find the container with id"
grep -Rh "can't find the container with id" $1 | sort | uniq | wc -l
echo -e ""
echo -e "DeleteContainer returned error"
grep -Rh "DeleteContainer returned error" $1 | sort | uniq | wc -l
echo -e ""
echo -e "timeout"
grep -Rh "timeout" $1 | sort | uniq | wc -l
echo -e ""
echo -e "failed to connect service"
grep -Rh "failed to connect service" $1 | sort | uniq | wc -l
echo -e ""
echo -e "Connection reset by peer"
grep -Rh "Connection reset by peer" $1 | sort | uniq | wc -l
echo -e ""
echo -e "Layer4 timeout"
grep -Rh "Connection reset by peer" $1 | sort | uniq | wc -l
echo -e ""
