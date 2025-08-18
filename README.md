# openshift etcd-tools

## must-gather-analyzer.sh

ETCD script will make collect info from MUST-GATHER, make little summary and search for errors/issues and explains what are expected values.
To use it, run

> ./must-gather-analyzer.sh [full path to MUST-GATHER]

or if you're missing clusterversion in your logs, here is exa

> ./must-gather-analyzer.sh [full path to MUST-GATHER]   



## must-gather-log_merger.sh

will combine logs from ETCD, haproxy, router, apiserver into one timeline printing only errors/warnings.

> ./must-gather-log_merger.sh -m <full path to MUST-GATHER>

## etcd-analyzer.sh

do 

> oc login

> ./etcd-analyzer.sh

and it will print summary of warnings, size of ETCD and number of objects.

## cleanup-analyzer.sh

do 

> oc login

> ./cleanup-analyzer.sh

and it will print number of deployments, replicasets and how many of them are inactive and could be cleaned up.

## fio_suite

fio_suite is benchmark tool which runs several fio tests to see how IOPS change under different load.

Run

> ./fio_suite.sh

or on RHCOS/Openshift

```
$ oc debug node/<master_node>
  [...]
  sh-4.4# chroot /host bash
  podman run --privileged --volume /var/lib/etcd:/test quay.io/peterducai/openshift-etcd-suite:latest fio
```

## secure_collector.sh

```
./secure_collector.sh <path to Must-gather or folder with logs>
```

will print number of errors (from list of errors) in all files.

<!-- 
> FOLLOWING TEXT IS OUTDATED AND NEED FIXES

tools to troubleshoot ETCD on Openshift 4

For easy use of container you can create alias for openshift-etcd-suite

> alias oes="podman run --volume /$(pwd):/test:Z quay.io/peterducai/openshift-etcd-suite:latest"

to build container just run

> buildah bud -t openshift-etcd-suite:latest .

*IMPORTANT*: latest version requires gnuplot and will create <timestamp> folder (with generated charts) in HOME.

## etcd.sh script

ETCD script will make collect info from ETCD pods, make little summary and search for errors/issues and explains what are expected values.

Fastest way to use it with must-gather is 

```
alias etcdcheck='podman run --privileged --volume /$(pwd):/test quay.io/peterducai/openshift-etcd-suite:latest etcd '
etcdcheck /test/<path to must-gather>
```

**You dont have to use full path, but /test/ is important**

You can either do *oc login* and then run

> chmod +x etcd.sh && ./etcd.sh

> ./etcd.sh /\<path-to-must-gather\>

or 

> podman run --privileged --volume /$(pwd):/test quay.io/peterducai/openshift-etcd-suite:latest etcd /test/\<path-to-must-gather\>


## fio_suite

fio_suite is benchmark tool which runs several fio tests to see how IOPS change under different load.

Run

> ./fio_suite.sh

or thru podman/docker

> podman run --volume /$(pwd):/test:Z quay.io/peterducai/openshift-etcd-suite:latest fio

but on RHCOS run

> podman run --privileged --volume /$(pwd):/test quay.io/peterducai/openshift-etcd-suite:latest fio

or to benchmark disk where ETCD resides

> podman run --privileged --volume /var/lib/etcd:/test quay.io/peterducai/openshift-etcd-suite:latest fio

**NOTE:** don't run it in / or /home/user as its top folder and you get Selinux error

```
podman run --privileged --volume /$(pwd):/test quay.io/peterducai/openshift-etcd-suite:latest fio
FIO SUITE version 0.1
 
WARNING: this test will run for several minutes without any progress! Please wait until it finish!
 
- [MAX CONCURRENT READ] ---
This job is a read-heavy workload with lots of parallelism that is likely to show off the device's best throughput:
 
  read: IOPS=4282, BW=268MiB/s (281MB/s)(1024MiB/3826msec)
  read: IOPS=3760, BW=235MiB/s (246MB/s)(200MiB/851msec)
- [REQUEST OVERHEAD AND SEEK TIMES] ---
This job is a latency-sensitive workload that stresses per-request overhead and seek times. Random reads.
 
  read: IOPS=258k, BW=1009MiB/s (1058MB/s)(1024MiB/1015msec)
  read: IOPS=263k, BW=1026MiB/s (1075MB/s)(200MiB/195msec)
 
- [SEQUENTIAL IOPS UNDER DIFFERENT READ/WRITE LOAD] ---
 
-- [ SINGLE JOB, 70% read, 30% write] --
 
  write: IOPS=41.6k, BW=162MiB/s (170MB/s)(308MiB/1894msec); 0 zone resets
  write: IOPS=42.5k, BW=166MiB/s (174MB/s)(59.9MiB/361msec); 0 zone resets
-- [ SINGLE JOB, 30% read, 70% write] --
 
  write: IOPS=35.7k, BW=139MiB/s (146MB/s)(140MiB/1002msec); 0 zone resets
  write: IOPS=35.4k, BW=138MiB/s (145MB/s)(715MiB/5171msec); 0 zone resets
-- [ 8 PARALLEL JOBS, 70% read, 30% write] --
 
  write: IOPS=5662, BW=22.1MiB/s (23.2MB/s)(91.4MiB/4130msec); 0 zone resets
  write: IOPS=5632, BW=22.0MiB/s (23.1MB/s)(59.6MiB/2708msec); 0 zone resets
-- [ 8 PARALLEL JOBS, 30% read, 70% write] --
 
  write: IOPS=6202, BW=24.2MiB/s (25.4MB/s)(140MiB/5765msec); 0 zone resets
  write: IOPS=6219, BW=24.3MiB/s (25.5MB/s)(485MiB/19974msec); 0 zone resets
 
- END -----------------------------------------

```



[![Docker Repository on Quay](https://quay.io/repository/peterducai/openshift-etcd-suite/status "Docker Repository on Quay")](https://quay.io/repository/peterducai/openshift-etcd-suite) -->
