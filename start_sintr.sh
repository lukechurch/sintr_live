# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Run this from the root of the sintr_live checkout

# This script starts all the local code needed for running sintr

# It results in:
# The Sintr Front End Server running on port 8989


if [ "$#" -ne 1 ]; then
    echo "Usage start_sintr.sh gce_project_id"
    exit 1
fi

cd ui
pub serve &> ~/sintr-logs/ui-pub-serve.log &
cd ..

mkdir -p ~/sintr-logs

# Front End Server
./infrastructure/scripts/start_fe_server.sh $1 # &> ~/sintr-logs/fe_server.log &
