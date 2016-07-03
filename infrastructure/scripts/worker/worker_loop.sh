# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This is the main worker execution loop

if [ "$#" -ne 1 ]; then
    echo "Usage worker_loop.sh gce_project_id"
    exit 1
fi

mkdir -p ~/sintr-logs

PATH=$PATH:/usr/lib/dart/bin

while true; do
  INSTANCE_ID=$(curl http://metadata/computeMetadata/v1/instance/hostname -H "Metadata-Flavor: Google")
  NOW=$(date +"%Y-%m-%d-%H-%M-%S")

  # startup.dart project_name job_name worker_folder
  # dart -c ~bin/startup.dart liftoff-dev $JOB_NAME $(readlink -f ~/src/sintr/job_code)/ > ../$INSTANCE_ID-$NOW.log 2>&1 & ./watchdog.sh 300 ../$INSTANCE_ID-$NOW.log $!
  dart -c ~/infrastructure/bin/startup.dart $1 > ~/sintr-logs/$INSTANCE_ID-$NOW.log 2>&1 & \
    ~/infrastructure/scripts/worker/watchdog.sh 300 ~/sintr-logs/$INSTANCE_ID-$NOW.log $!

  # Upload the logs
  gsutil cp ~/sintr-logs/$INSTANCE_ID-$NOW.log gs://$1-sintr-logs
  sleep 5
done
