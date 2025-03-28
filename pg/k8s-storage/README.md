# Scripts used to run PG benchmarking tests

## Steps for running pgbench tests

1. Setup PG cluster using [Percona Operator for postgresSQL](https://docs.percona.com/percona-operator-for-postgresql/2.0/index.html) by setting the [storageclass](https://github.com/percona/percona-postgresql-operator/blob/988cd8a7ef01b1171ee4c3346c1138970edc00fa/deploy/cr.yaml#L223) associated with the storage.
2. Modify the script pgbench.sh based on your requirements. For example, config is referenced with the name storage-name
3. Run pgbench <leader-pod-identifier> <identifier-of-storage> <results-location>
   <leader-pod-identifier> : Check the leader by using patronictl
   <identifier-of-storage> : Any identifier for differentiating storage name
   <results-location> : Location where results are stored


## Steps for running fio tests

1. Build image using Dockerfile present at fio/ directory. 
2. Add the image details in `fio/fio.yaml`. Run job `fio/fio.yaml` 