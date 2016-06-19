# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This script installs Dart on a clean linux compute engine instance

# Install Dart
# Enable HTTPS for apt.
sudo apt-get update
sudo apt-get install apt-transport-https

# Get the Google Linux package signing key.
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'

# Set up the location of the stable repository.
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update

sudo apt-get install dart
sudo apt-get install git -y

# Add Dart to the path
PATH=$PATH:/usr/lib/dart/bin
