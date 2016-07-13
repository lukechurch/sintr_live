# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Run this from the root of the sintr_live checkout

# This script starts all the local code needed for running sintr
# This version executes without a cloud project

# It results in:
# The Sintr Front End Server running on port 8990


if [ "$#" -ne 1 ]; then
    echo "Usage start_sintr_local.sh projectPath"
    exit 1
fi

mkdir -p ~/sintr-logs

cd ui
pub serve &> ~/sintr-logs/ui-pub-serve.log &

cd ..

# Front End Server
./infrastructure/scripts/start_fe_server.sh - demo/ # &> ~/sintr-logs/fe_server.log
