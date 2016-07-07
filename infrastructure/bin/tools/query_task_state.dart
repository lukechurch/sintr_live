// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This tool displays the task objects status project's datastore

import 'dart:io';

import 'package:sintr_live_common/configuration.dart' as config;
import 'package:sintr_live_common/logging_utils.dart' as log;
import 'package:sintr_live_common/auth.dart' as auth;
import 'package:sintr_live_common/tasks.dart' as tasks;
import 'package:gcloud/src/datastore_impl.dart' as datastore_impl;
import 'package:gcloud/db.dart' as db;
import 'package:gcloud/service_scope.dart' as ss;

main(List<String> args) async {
  if (args.length < 1) {
    print("Usage: dart query_task_state cloud_project_id");
    exit(1);
  }

  log.setupLogging();

  String projectId = args[0];

  config.configuration = new config.Configuration(projectId,
      cryptoTokensLocation:
          "${config.userHomePath}/Communications/CryptoTokens");

  var client = await auth.getAuthedClient();

  tasks.TaskController taskController =
      new tasks.TaskController("example_task");

  var datastore = new datastore_impl.DatastoreImpl(client, 's~$projectId');
  var datastoreDB = new db.DatastoreDB(datastore);

  log.info("Setup done");

  await ss.fork(() async {
    db.registerDbService(datastoreDB);

    Map<String, Map<int, int>> status = await taskController.queryTaskState();

    for (String job in status.keys) {
      var results = status[job].keys.map((k) => "${tasks.LifecycleState.values[k]}: ${status[job][k]}");
      log.info("$job: ${status[job]} ${results.join(" ")}");

      // var readyCount = status[job][tasks.LifecycleState.READY.index];
    }
  });
}
