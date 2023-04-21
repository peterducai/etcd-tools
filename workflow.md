# Generic

Latency (network, storage) should be stable whole time as excessive peaks could mean problem for ETCD (and therefor whole cluster). Even only few minutes lasting peak in latency could mean timeout on ETCD, API and oauth pods and cause inability to login to cluster.

## Master node size

Examine size of cluster, apart from regular sizes you could find also non-common setup which can be confusing (small cluster with too much resources or opposite).

Example:

single node (SNO) cluster running on node with 64 CPUs is stronger than 3 node cluster with 8 CPU nodes.

## Cluster size

average sizing would be

```
small - SNO, Edge or up to 5 workers and no infra
medium - 10-20 workers and few infra
large - 20+ workers and 6+ infras
huge - 50-100+ workers and 10-20+ infras
```

small cluster with minimum or medium resources is good only for local development or demo or SNO/Edge scenarios

### CPU

Check the load (number of installed operators/pipelines and how heavy they are) and check if master nodes have enough CPU.

```
minimum - 4 CPU, good only for local development or demo
medium - 8 CPU, good for small to medium cluster with average load
large - 16 CPU, good for small to medium cluster with heavy load (or too many operators, pipelines, etc..) or large cluster with average load
huge - 20+ CPU, good for large cluster with heavy load
```

### Memory

RAM depends heavily on installed operators (for example logging can be quite heavy on CPU and RAM).



# CPU

## iowait 

values should be below 4.0. Values over 8.0 are alarming. Always check sizing of nodes if they have enough CPU/RAM if you see high iowait.


# Storage


## Generic storage behaviour

There's always will be pros and cons as you cannot have storage that would have best concurrent IOPS but also sequential, or super high IOPS and super low latency. Customer should find balance between DB/ETCD related performance and generic (worker load) performance.


## Metrics


## IOPS

[fio suite]

Importance of data is in following order. Make sure you get data with highest priority first and examine them first. 

1. Fsync latency and fsync sequential IOPS (is storage tweaked for ETCD?)
2. LibIAO sequential IOPS  (is storage tweaked for sequential IO in general?)
3. Random, concurrent IOPS  (while being tweaked for sequential IOPS, how storage can handle concurrent?)

Never make conclusion only from one metric alone, but rather look at combination of data and importance/priority of the data.

Example of small/medium cluster:

| fsync seq.     | libiao seq.     | random/concurrent    | outcome | solution                                                                                                                      |
|----------------|-----------------|---------------|---------|-------------------------------------------------------------------------------------------------------------------------------|
| IOPS below 300 | IOPS below 1000 | 10k+ IOPS     | BAD     | storage is optimized for concurrent IOPS but ETCD requires sequential                                                         |
| 300-600 IOPS   | 1500-2500 IOPS  | below 10k     | GOOD    |                                                                                                                               |
| 900+ IOPS      | 4000-6000+ IOPS       | very low IOPS | BAD     | storage is optimized too much for ETCD but not for other things. High concurrent IO could degrade sequential IO a lot. |

**IMPORTANT:** all numbers in example are just rough estimates and shouldn't be taken as exact threshold. Don't focus just on numbers but also on gap between different values.


## Latency

### How to read fio/fio_suite output

<pre>
```
cleanfsynctest: (groupid=0, jobs=1): err= 0: pid=89: Tue Sep 27 16:39:22 2022
  <b>write: IOPS=230</b>, BW=517KiB/s (529kB/s)(22.0MiB/43595msec); 0 zone resets           <i><--- fsync sequential IOPS</i>
    clat (usec): min=4, max=37506, avg=63.37, stdev=393.00
     lat (usec): min=4, max=37508, avg=64.45, stdev=393.12
    clat percentiles (usec):
     |  1.00th=[    7],  5.00th=[   16], 10.00th=[   18], 20.00th=[   20],
     | 30.00th=[   25], 40.00th=[   27], 50.00th=[   31], 60.00th=[   42],
     | 70.00th=[   63], 80.00th=[   88], 90.00th=[  122], 95.00th=[  143],
     | 99.00th=[  334], 99.50th=[  717], 99.90th=[ 1369], 99.95th=[ 1516],
     | 99.99th=[ 6652]
   bw (  KiB/s): min=   49, max= 1105, per=99.86%, avg=516.54, stdev=283.00, samples=87
   iops        : min=   22, max=  492, avg=230.16, stdev=125.97, samples=87
  lat (usec)   : 10=2.22%, 20=19.09%, 50=43.13%, 100=20.00%, 250=14.21%
  lat (usec)   : 500=0.59%, 750=0.28%, 1000=0.20%
  lat (msec)   : 2=0.24%, 10=0.02%, 50=0.01%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=1245, max=293908, avg=4270.40, stdev=6256.20
    sync percentiles (usec):
     |  1.00th=[ 1532],  5.00th=[ 1811], 10.00th=[ 1926], 20.00th=[ 2180],
     | 30.00th=[ 2704], 40.00th=[ 3130], 50.00th=[ 3294], 60.00th=[ 3490],
     | 70.00th=[ 3785], 80.00th=[ 4359], 90.00th=[ 5538], 95.00th=[ 6456],
     | <b>99.00th=[38011]</b>, 99.50th=[43254], <b>99.90th=[62653]</b>, 99.95th=[65799],     <i><--- 99.0th and 99.9th percentile that should be below 10k</i>
     | 99.99th=[73925]
```
</pre>

required fsync sequential IOPS:

* 50 - minimum, local development
* 300 - medium cluster with average load
* 600 - medium or large cluster
* 900+ - large cluster with heavy load

## etcd_disk_wal_fsync_duration 99th and 99.9th

should be lower than 10ms

```
>2ms = superb, probably NVMe on baremetal or AWS with io1 disk and 2000 IOPS set.
>5ms = great, usually well performing virtualized platform
5-7ms = OK
8-10ms = close to threshold, NOT GOOD if any peaks occur
```

> some versions may suggest that threshold is 20ms. Still, check docs and evaluate how many percents close to threshold value is and asses performance risk. Values above 15ms are also not good as they are close to threshold of 20ms.

> Usually when 99th is close to threshold, we will see 99.9th going above threshold, which means storage can barely provide required performance (for ETCD) and it's really better when 99.0th is below 10ms.


## etcd_disk_backend_commit_duration 99th

should be lower than 25ms

# Network

Big network latency and packet drops can also bring an unreliable etcd cluster state, so network health values (RTT and packet drops) should be monitored. 

## RX/TX errors and dropped packets

<pre>
```
ip -s link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    RX:  bytes packets errors dropped  missed   mcast           
          8296      94      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
          8296      94      0       0       0       0 
2: enp0s31f6: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state UP mode DORMANT group default qlen 1000
    link/ether 20:1e:88:99:df:2c brd ff:ff:ff:ff:ff:ff
    RX:  bytes packets errors <b>dropped</b>  missed   mcast     <i><--- check RX/TX errors and dropped packets     </i> 
    1993837469 1821202      0      <b>22</b>       0       0 
    TX:  bytes packets errors dropped carrier collsns           
     171129355  506637      0       0       0       0 
```
</pre>


## etcd_network_peer_round_trip_time 99th 

should be lower than 50ms. Values of 40+ mean network latency is close to threshold and any peak could degrade ETCD performance.






# ETCD size

## Object count

* small cluster - even 1-2k of objects could cause issues. Cluster should be extended to medium one for such workload.
* medium cluster - ~8k of objects could cause issues, having huge secrets/keys could mean problems even with lower number (~6k)
* large cluster
* huge cluster - with too heavy load and object count 10k+ it could mean that in future load will reach limits and have to be split onto several smaller clusters

You can get object count with

```
$ oc project openshift-etcd
oc get pods
oc rsh <etcd pod>
> etcdctl get / --prefix --keys-only | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn
```

or with [etcd_analyzer.sh](https://github.com/peterducai/etcd-tools/blob/main/etcd-analyzer.sh)

With [cleanup_analyzer.sh](https://github.com/peterducai/etcd-tools/blob/main/cleanup-analyzer.sh) you can find out excessive number of inactive objects (images, deployments, etc..)


## Object size

If secret holds huge token, certifikate or SSH key, it might get performance problem even with less secrets than 8k (on small to medium cluster).
Check also namespaces for big amount of objects (mainly secrets). User namespace with excessive number (30+) of secrets should be ideally cleaned up.

```
oc get secrets -A --no-headers | awk '{ns[$1]++}END{for (i in ns) print i,ns[i]}'
```