// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Run from the root of the sintr_live checkout
// Generally this should be used via the set_worker_count.sh script

import 'dart:io';

import 'package:sintr_live_infrastructure/worker_machines_utils.dart';

main(List<String> args) async {
  if (args.length != 2) {
    print ("Usage: set_worker_count.dart project-id count");
    exit(1);
  }
  String projectID = args[0];
  int targetCount = int.parse(args[1]);

  await setWorkerCount(projectID, targetCount);
}
