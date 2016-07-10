# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Run this from the root of the sintr_live checkout

# This script starts all the local code needed for running sintr
# This version executes without a cloud project

# It results in:
# The Sintr Front End Server running on port 8990


if [ "$#" -ne 0 ]; then
    echo "Usage start_sintr_local.sh"
    exit 1
fi

# Shutdown any existing processes
kill $(lsof -t -i:8080)   # pub serve
kill $(lsof -t -i:11001)  # sintr-server-mock
kill $(lsof -t -i:8990)   # sintr fe

mkdir -p ~/sintr-logs

# Front End Server
./infrastructure/scripts/start_fe_server.sh - &> ~/sintr-logs/fe_server.log &
dart ui/sintr-server-mock/server.dart &> ~/sintr-logs/sintr-mock-server.log &
cd ui
pub serve &> ~/sintr-logs/ui-pub-serve.log &
