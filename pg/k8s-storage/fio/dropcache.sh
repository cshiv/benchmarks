#!/bin/bash
echo 3 > /proc/sys/vm/drop_caches # Clear Pod Cache
echo 3 > /host/proc/sys/vm/drop_caches # Clear Host node Cache
