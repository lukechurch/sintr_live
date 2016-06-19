# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Set the worker count for each count destroying or comissioning the nodes as needed

if [ "$#" -ne 2 ]; then
    echo "Usage set_worker_count gce_project_id count"
    exit 1
fi

dart infrastructure/scripts/set_worker_count.dart $1 $2
