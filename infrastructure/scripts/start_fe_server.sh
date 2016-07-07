# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Run this from the root of the sintr_live checkout

# This script starts the Sintr front end server

if [ "$#" -ne 1 ]; then
    echo "Usage start_fe_server.sh gce_project_id"
    exit 1
fi

dart infrastructure/fe_server/startup.dart $1 8990
