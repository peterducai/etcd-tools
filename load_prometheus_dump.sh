#!/bin/bash

# https://access.redhat.com/solutions/5482971

tar -xvf dump.tar.gz -C /tmp/data
mv /tmp/data/prometheus/* /tmp/prometheus-2.24.1.linux-amd64/data
mkdir /tmp/prometheus-config
touch /tmp/prometheus-config/prometheus.yml
podman run --rm -p 9090:9090/tcp -v /tmp/prometheus-2.24.1.linux-amd64/data:/prometheus  -v /tmp/prometheus-config:/prometheus-config --privileged quay.io/prometheus/prometheus --storage.tsdb.path=/prometheus --config.file=/prometheus-config/prometheus.yml --storage.tsdb.retention=100d


#firefox http://localhost:9090/