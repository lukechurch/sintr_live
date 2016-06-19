# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This code configures and starts a worker image

if [ "$#" -ne 1 ]; then
    echo "Usage worker_startup.sh gce_project_id"
    exit 1
fi


# Pull the infrasturcture
gsutil cp gs://$1-sintr-infrastructure/sintr-infrastructure-image.tar.gz .
tar -xf sintr-infrastructure-image.tar.gz

# Install dart
~/infrastructure/scripts/worker/install_dart.sh

# Pub get
find . -type f -name 'pubspec.yaml' \
  -exec sh -c '(publican=$(dirname {}) && cd $publican && /usr/lib/dart/bin/pub get)' \;


# Deploy crypto tokens
mkdir -p ~/Communications/CryptoTokens
gsutil cp gs://$1-sintr-crypto-tokens/* ~/Communications/CryptoTokens


# Start worker loop
~/infrastructure/scripts/worker/worker_loop.sh $1
