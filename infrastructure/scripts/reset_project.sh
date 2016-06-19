# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Setup a project to use sintr

# Deploy cluster of sintr workers

if [ "$#" -ne 1 ]; then
    echo "Usage setup_project gce_project_id"
    exit 1
fi


echo "Resetting "$1
echo "This will delete all input, logs and results"

read -p "Proceed Y/(n)? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Y]$ ]]
then
    exit 1
fi

echo "Emptying buckets"


gsutil -m rm -r gs://$1-sintr-data-source/*
gsutil -m rm -r gs://$1-sintr-results/*

gsutil -m rm -r gs://$1-sintr-logs/*

gsutil -m rm -r gs://$1-sintr-infrastructure/*
gsutil -m rm -r gs://$1-sintr-crypto-tokens/*
