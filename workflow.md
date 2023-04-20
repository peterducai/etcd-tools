# Generic

## Master node size

### CPU

```
minimum - 4 CPU, good only for local development or demo
medium - 8 CPU, good for small to medium cluster with average load
large - 16 CPU, good for small to medium cluster with heavy load (or too many operators, pipelines, etc..) or large cluster with average load
huge - 20+ CPU, good for large cluster with heavy load
```

### Memory

RAM depends heavily on installed operators (for example logging can be quite heavy on CPU and RAM).


## Cluster size

average sizing would be

```
small - SNO, Edge or up to 5 workers and no infra
medium - 10-20 workers and few infra
large - 20+ workers and 6+ infras
huge - 100+ workers and 10-20+ infras
```

small cluster with minimum or medium resources is good only for local development or demo or SNO/Edge scenarios



# CPU

## iowait 

values should be below 4.0. Values over 8.0 are alarming.


# Storage


## Generic storage behaviour

There's always will be pros and cons as you cannot have storage that would have best concurrent IOPS but also sequential, or super high IOPS and super low latency. Customer should find balance between DB/ETCD related performance and generic (worker load) performance.

Usual scenarios:

* high concurrent IOPS, small sequential IOPS, variable latency - NOT GOOD, not fit for ETCD
* high sequential IOPS, super low concurrent IOPS, variable latency - NOT GOOD, too much tweaked for ETCD but lacking performance for anything else.

## Setup


## Metrics


## IOPS

[fio suite]

Importance of data is in following order. Make sure you get data with highest priority first and examine them first. 

1. Fsync latency and fsync sequential IOPS (is storage tweaked for ETCD?)
2. LibIAO sequential IOPS  (is storage tweaked for sequential IO in general?)
3. Concurrent IOPS  (while being tweaked for sequential IOPS, how storage can handle concurrent?)

Never make conclusion only from one metric alone, but rather look at combination of data and importance/priority of the data.

| fsync seq.     | libiao seq.     | concurrent    | outcome | solution                                                                                                                      |
|----------------|-----------------|---------------|---------|-------------------------------------------------------------------------------------------------------------------------------|
| IOPS below 300 | IOPS below 1000 | 10k+ IOPS     | BAD     | storage is optimized for concurrent IOPS but ETCD requires sequential                                                         |
| 300-600 IOPS   | 1500-2500 IOPS  | below 10k     | GOOD    |                                                                                                                               |
| 900+ IOPS      | 6000 IOPS       | very low IOPS | BAD     | storage is optimezd too much for ETCD but not for other things. High concurrent IO could degrade sequential processing a lot. |

### etcd_disk_wal_fsync_duration 99th and 99.9th

should be lower than 10ms

```
>2ms = superb, probably NVMe on baremetal
>5ms = great
5-7ms = OK
8-10ms = close to threshold, NOT GOOD
```

> some versions may suggest that threshold is 20ms. Still, we evaluate how many percents close to threshold value is and asses performance risk. Values above 15ms are also not good as they are close to threshold of 20ms.

Usually when 99th is close to threshold, we will see 99.9th going above threshold, which means storage can barely provide required performance (for ETCD)



# Network

## RX/TX errors and dropped packets



## etcd_network_peer_round_trip_time 99th 

should be lower than 50ms




## Metrics



### etcd_disk_backend_commit_duration 99th should be lower than 25ms





# ETCD size

## Object count

* small cluster - even 1-2k of objects could cause issues. Cluster should be extended to medium one for such workload.
* medium cluster - ~8k of objects could cause issues, having huge secrets/keys could mean problems even with lower number (~6k)
* large cluster
* huge cluster - with too heavy load and object count 10k+ it could mean that in future load will reach limits and have to be split onto several smaller clusters


## Object size

If secret holds huge token, certifikate or SSH key, it might get performance problem even with less secrets than 8k.