#!/bin/bash

if [ -z "$FIO_STORAGE_DIR" ]; then
    echo "Please set the variable ${FIO_STORAGE_DIR} and run the program"
    exit -1
fi
mkdir -p ${FIO_STORAGE_DIR}/fiotest/
echo "Running fio test DO NOT STOP IT Start $(date +'%Y-%m-%d %H:%M:%S')"
echo "================================================================="
echo "FIO_STORAGE_DIR  = ${FIO_STORAGE_DIR}/fiotest/"

for conf in ${FIO_CONFIG_FILES}; do 
    echo "Running "$conf; 
    fio --directory=${FIO_STORAGE_DIR}/fiotest/ --minimal $conf.cfg >> results$(date +'%Y-%m-%d-%H-%M')_$conf.txt; 
    rm -rf $FIO_STORAGE_DIR/fiotest/*
done
echo "Process END at $(date +'%Y-%m-%d %H:%M:%S')"

# Needs to be replaced. This is present only to copy the run files
tail -f /dev/null