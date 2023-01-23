#!/bin/bash

## Simple script to create a snapshot of all servers on an Exoscale organization, export them and upload inot a S3 bucket within the same organization
## This script is not maintained in any way by Exoscale
## This script does not delete any Snapshots on the virtual systems or on the bucket. Cleanup needs to be manually
## The script creates cost for snapshots and S3 bucket usage each run

## exo CLI needs to be configure on the server running this script. Please look at https://community.exoscale.com/documentation/tools/exoscale-command-line-interface/ how to configure

# Define the path where the snapshot should be stored on the local disk of the server running the script to buffer before upload. Disk needs to be sufficient in size to take the largest snapshot once
path="/mnt/data/snapshotfolder"
# name the bucket where the snapshots should be uploaded to
bucket="mybucket"

servers=$( exo compute instance list | awk '{print $4}' | tail -n +3)
for server in $servers; do
        exo compute instance snapshot create $server
        snapdate=$( exo compute instance snapshot list | grep $server | awk '{print $4}' | sort | tail -n 1 )
        lastsnapid=$( exo compute instance snapshot list | grep $server | grep $snapdate | awk '{print $2}' )
        exportout=$( exo compute instance snapshot export $lastsnapid )
        url=$( echo $exportout | awk '{print $4}' )
        wget "$url" -O $path/$server.$snapdate.snapshot
        exo storage upload $path/$server.$snapdate.snapshot $bucket
        rm -rf $path/$server.$snapdate.snapshot
done
