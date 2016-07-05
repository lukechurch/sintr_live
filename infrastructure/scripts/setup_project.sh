# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Setup a project to use sintr

# Deploy cluster of sintr workers
# Run this from the root of the sintr_live checkout

# It expects the crypto token for the project to be in
# ~/Communications/CryptoTokens/

if [ "$#" -ne 1 ]; then
    echo "Usage setup_project gce_project_id"
    exit 1
fi

echo "Starting setup for "$1

echo "Creating buckets"

gsutil mb -p $1 gs://$1-sintr-data-source
gsutil mb -p $1 gs://$1-sintr-results

gsutil mb -p $1 gs://$1-sintr-logs

gsutil mb -p $1 gs://$1-sintr-infrastructure
gsutil mb -p $1 gs://$1-sintr-crypto-tokens

# From here everything should run without errors
set -e

./infrastructure/scripts/update_infrastructure.sh $1

# Deploy the crypto keys
gsutil cp ~/Communications/CryptoTokens/$1.json gs://$1-sintr-crypto-tokens

# Setup the needed indecies 
gcloud --quiet preview --project $1 \
  datastore create-indexes infrastructure/index.yaml
