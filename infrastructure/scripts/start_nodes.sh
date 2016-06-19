# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Deploy nodes into a cluster
if [ "$#" -ne 3 ]; then
    echo "Usage start_nodes gce_project_id zone count_to_start"
    exit 1
fi

PROJECT=$1
ZONE=$2
NODE_COUNT=$3
NOW=$(date +"%Y-%m-%d-%H-%M-%S")

WORKER_BASE_NAME=sintr-worker-$NOW--

echo "Deploying $NODE_COUNT nodes in zone $2"

for i in `seq 1 $NODE_COUNT`;
do
   WORKER_NAME=$WORKER_BASE_NAME$i
   echo "Deploying " $WORKER_NAME

   gcloud compute --project $PROJECT instances \
    create $WORKER_NAME \
    --zone $ZONE \
    --machine-type "custom-1-6656" \
    --network "default" \
    --maintenance-policy "TERMINATE" \
    --preemptible \
    --scopes "https://www.googleapis.com/auth/cloud-platform" \
    --image "https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/ubuntu-1404-trusty-v20150909a" \
    --boot-disk-size "50" \
    --boot-disk-type "pd-standard" \
    --boot-disk-device-name $WORKER_NAME &
done
wait  # Join on start
sleep 5

echo "Nodes ready, initting"

for i in `seq 1 $NODE_COUNT`;
do
   WORKER_NAME=$WORKER_BASE_NAME$i
   echo "Init " $WORKER_NAME
   gcloud compute --project $PROJECT \
    ssh --zone $ZONE $WORKER_NAME \
    "gsutil cp gs://$PROJECT-sintr-infrastructure/worker_startup.sh .; chmod +x worker_startup.sh; screen -d -m ./worker_startup.sh $PROJECT" &
done
wait

echo "Deployment complete"
