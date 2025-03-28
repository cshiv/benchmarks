#!/bin/bash

# Usage: pgbench <leader-pod> <identifier-of-storage> <results-location>
# Pre-requisites: kubectl config is stored as <identifier-of-storage>.cfg

leader=$1 # Define the leader pod, Manual action
storage_type=$2
results_location=$3


#pgbench_init_scale=(1000 5000 10000)
pgbench_init_scale=(1000 5000 10000)
connections=(50 100 200 300)
#connections=(100)
pgbench_run_time=7200

export KUBECONFIG="${2}.cfg"
KUBECTL_CMD="kubectl"
# Create  pg-client pod

${KUBECTL_CMD} apply -f ./pgbench-pod.yaml
sleep 20
for scale_factor in "${pgbench_init_scale[@]}"

do
    # Create pgbench table
    ${KUBECTL_CMD} exec ${leader} -- psql -c  "create database pgbench with owner tpcc"
    # Cleanup the stats
    ${KUBECTL_CMD} exec ${leader} -- psql -c  "select pg_stat_reset_shared('io');"

    # Initialize pgbench
    # ${KUBECTL_CMD} run pg-client --image=perconalab/percona-distribution-postgresql:16 --env="PGPASSWORD=tpcc" --command -- tail -f /dev/null 
    echo "Initializing PGBench with ${scale_factor} started at `date`"
    ${KUBECTL_CMD} exec pg-client -- pgbench -q -h cluster1-primary.${storage_type}.svc.cluster.local -U tpcc -i -I "dtgvp" -s ${scale_factor} pgbench
    echo "Initializing PGBench with ${scale_factor} completed at `date`"
    # Gather Stats
    ${KUBECTL_CMD} exec ${leader} -- psql -c  "copy(SELECT * FROM pg_stat_io WHERE reads <> 0 OR writes <> 0 OR extends <> 0) TO '/tmp/${storage_type}-Init.csv' WITH (FORMAT csv)"
    ${KUBECTL_CMD} cp ${leader}:/tmp/${storage_type}-Init.csv ${results_location}/${storage_type}-Init.csv
    ${KUBECTL_CMD} exec ${leader} -- sh -c 'psql -c "SELECT * FROM pg_stat_io WHERE reads <> 0 OR writes <> 0 OR extends <> 0"' > ${results_location}/${storage_type}-Init.txt

    # Cleanup the stats
    ${KUBECTL_CMD} exec ${leader} -- psql -c  "select pg_stat_reset_shared('io');"

    # Test for different set of Connections and Jobs
    for num in "${connections[@]}"
    do
        # Run for simple-update
        echo "Running test for Simple-update"
        echo "LOG:Simple-update for scale factor ${scale_factor} and connections ${num} started at `date`"        
        ${KUBECTL_CMD} exec pg-client -- sh -c "pgbench -h cluster1-primary.${storage_type}.svc.cluster.local -U tpcc -c ${num} -j ${num} -b simple-update -T ${pgbench_run_time} --progress=30 pgbench" >${results_location}/${storage_type}_simple-update_c${num}j${num}.log
        echo "LOG:Simple-update for scale factor ${scale_factor} and connections ${num} completed at `date`"        
        ${KUBECTL_CMD} exec ${leader} -- psql -c  "copy(SELECT * FROM pg_stat_io WHERE reads <> 0 OR writes <> 0 OR extends <> 0) TO '/tmp/${storage_type}-simple-update-c${num}j${num}.csv' WITH (FORMAT csv)"
        ${KUBECTL_CMD} cp ${leader}:/tmp/${storage_type}-simple-update-c${num}j${num}.csv ${results_location}/${storage_type}-simple-update-c${num}j${num}.csv
        ${KUBECTL_CMD} exec ${leader} -- sh -c 'psql -c "SELECT * FROM pg_stat_io WHERE reads <> 0 OR writes <> 0 OR extends <> 0"' > ${results_location}/${storage_type}-simple-update-c${num}j${num}.txt
        
        # Cleanup the stats
        ${KUBECTL_CMD} exec ${leader} -- psql -c  "select pg_stat_reset_shared('io');"

        # Run for Select
        echo "Running test for Select"
        #${KUBECTL_CMD} exec pg-client -- sh -c "pgbench -h cluster1-primary.${storage_type}.svc.cluster.local -U tpcc -c ${num} -j ${num} -b select-only -T ${pgbench_run_time} pgbench" >${results_location}/${storage_type}_select_c${num}j${num}.log
        echo "LOG:Select for scale factor ${scale_factor} and connections ${num} started at `date`"        
        ${KUBECTL_CMD} exec pg-client -- sh -c "pgbench -h cluster1-primary.${storage_type}.svc.cluster.local -U tpcc -c ${num} -j ${num} -b select-only -T ${pgbench_run_time}  --progress=30  pgbench" >${results_location}/${storage_type}_select_c${num}j${num}.log
        echo "LOG:Select for scale factor ${scale_factor} and connections ${num} completed at `date`"        
        ${KUBECTL_CMD} exec ${leader} -- psql -c  "copy(SELECT * FROM pg_stat_io WHERE reads <> 0 OR writes <> 0 OR extends <> 0) TO '/tmp/${storage_type}-Select-c${num}j${num}.csv' WITH (FORMAT csv)"
        ${KUBECTL_CMD} cp ${leader}:/tmp/${storage_type}-Select-c${num}j${num}.csv ${results_location}/${storage_type}-Select-c${num}j${num}.csv
        ${KUBECTL_CMD} exec ${leader} -- sh -c 'psql -c "SELECT * FROM pg_stat_io WHERE reads <> 0 OR writes <> 0 OR extends <> 0"' > ${results_location}/${storage_type}-Select-c${num}j${num}.txt        
        
        # Cleanup the stats
        echo "Clean up stats"
        ${KUBECTL_CMD} exec ${leader} -- psql -c  "select pg_stat_reset_shared('io');"
    done
done    
