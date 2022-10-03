#!/bin/bash

buildah bud -t quay.io/openshift/etcd-tools/fio_suite:latest Dockerfile_fio
#podman tag quay.io/openshift/etcd-tools/fio_suite:latest quay.io/openshift/etcd-tools/fio_suite:0.1.28