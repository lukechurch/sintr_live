# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This script deploys the sintr infrastructure into its standard location in
# a project where the workers will deploy it from

# Run this from the root of the sintr_live checkout

if [ "$#" -ne 1 ]; then
    echo "Usage update_infrastructure gce_project_id"
    exit 1
fi

echo "Packaging infrasturcture"

tar -cz --exclude="packages" --exclude=".pub" -f sintr-infrastructure-image.tar.gz infrastructure

echo "Uploading infrasturcture -> " $1
gsutil mv sintr-infrastructure-image.tar.gz gs://$1-sintr-infrastructure
gsutil cp infrastructure/scripts/worker/worker_startup.sh gs://$1-sintr-infrastructure
