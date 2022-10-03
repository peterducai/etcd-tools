#!/bin/bash

buildah bud -t quay.io/openshift/etcd-tools/fio_suite:latest .
#podman tag quay.io/openshift/etcd-tools/fio_suite:latest quay.io/openshift/etcd-tools/fio_suite:0.1.28