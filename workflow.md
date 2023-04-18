# Generic


## Cluster size

average sizing would be


small - SNO, Edge or up to 10 workers
medium - 10-20 workers and few infra
large - 20+ workers and 6+ infras
huge - 100+ workers and 10-20+ infras


## Master node size

### CPU

minimum - 4 CPU, good only for local development or demo
medium - 8 CPU, good for small to medium cluster with average load
large - 16 CPU, good for small to medium cluster with heavy load (or too many operators, pipelines, etc..) or large cluster with average load
huge - 20+ CPU, good for large cluster with heavy load

### Memory

RAM depends heavily on installed operators (for example logging can be quite heavy on CPU and RAM).

# CPU

## iowait 

values should be below 4.0. Values over 8.0 are alarming.


# Storage


## Setup


## Metrics

### etcd_disk_wal_fsync_duration 99th and 99.9th

should be lower than 10ms

>5 = great
5-7ms = OK
8-10ms = close to threshold, NOT GOOD

> some versions may suggest that threshold is 20ms. Still, we evaluate how many percents close to threshold value is and asses performance risk. Values above 15ms are also not good as they are close to threshold of 20ms.

Usually when 99th is close to threshold, we will see 99.9th going above threshold, which means storage can barely provide required performance (for ETCD)



# Network

## RX/TX errors and dropped packets



## etcd_network_peer_round_trip_time 99th 

should be lower than 50ms




## Metrics



### etcd_disk_backend_commit_duration 99th should be lower than 25ms







## Object count

small cluster - even 1-2k of objects could cause issues. Cluster should be extended to medium one for such workload.
medium cluster - ~8k of objects could cause issues, having huge secrets/keys could mean problems even with lower number (~6k)
large cluster
huge cluster - with too heavy load and object count 10k+ it could mean that in future load will reach limits and have to be split onto several smaller clusters