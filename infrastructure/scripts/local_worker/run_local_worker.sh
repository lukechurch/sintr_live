# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Run this from the root of the sintr_live checkout

# This script runs a local worker node, it assumes that Dart is already installed

if [ "$#" -ne 1 ]; then
    echo "Usage run_local_worker.sh gce_project_id"
    exit 1
fi

# Update the infrastructure
./infrastructure/scripts/update_infrastructure.sh $1

rm -r ~/sintr-local-instrastructure
mkdir -p ~/sintr-local-instrastructure
cd ~/sintr-local-instrastructure

echo "Pulling Sintr infra"

# Pull the infrasturcture
gsutil cp gs://$1-sintr-infrastructure/sintr-infrastructure-image.tar.gz .
tar -xf sintr-infrastructure-image.tar.gz

echo "Running pub get"

find . -type f -name 'pubspec.yaml' \
  -exec sh -c '(publican=$(dirname {}) && cd $publican && pub upgrade)' \;

echo "Clearing logs"

rm -r ~/sintr-logs
mkdir -p ~/sintr-logs

while true; do
  INSTANCE_ID=LOCAL_WORKER
  NOW=$(date +"%Y-%m-%d-%H-%M-%S")

  echo "Running startup.dart"

  # startup.dart project_name job_name worker_folder
  # dart -c ~bin/startup.dart liftoff-dev $JOB_NAME $(readlink -f ~/src/sintr/job_code)/ > ../$INSTANCE_ID-$NOW.log 2>&1 & ./watchdog.sh 300 ../$INSTANCE_ID-$NOW.log $!
  dart -c ~/sintr-local-instrastructure/infrastructure/bin/startup.dart $1 > ~/sintr-logs/$INSTANCE_ID-$NOW.log 2>&1 > \
    ~/sintr-logs/$INSTANCE_ID-$NOW.log

  # Upload the logs
  # gsutil cp ~/sintr-logs/$INSTANCE_ID-$NOW.log gs://$1-sintr-logs
  sleep 5
done
