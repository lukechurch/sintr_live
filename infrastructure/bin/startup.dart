// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the entry point that is called by the worker nodes.
// If it returns it will be recalled again after a short delay by
// the infrastructure.

// It should ensure that it periodically writes progress reports to the
// console, about once a minute

import 'dart:async';
import 'dart:convert';

import 'package:sintr_live_common/configuration.dart' as config;
import 'package:sintr_live_common/logging_utils.dart' as log;
import 'package:sintr_live_common/auth.dart' as auth;
import 'package:sintr_live_common/tasks.dart' as tasks;
import 'package:sintr_live_infrastructure/evaluator.dart' as eval;


import 'package:gcloud/db.dart' as db;
import 'package:gcloud/src/datastore_impl.dart' as datastore_impl;
import 'package:gcloud/storage.dart' as storage;
import 'package:gcloud/service_scope.dart' as ss;

const JOB_NAME = "sintr-live-interactive-job";
const DELAY_BETWEEN_TASK_POLLS = const Duration(seconds: 60);

main(List<String> args) async {
  log.setupLogging();
  log.debug("Startup args: $args");

  String projectName = args[0];

  // Setup cloud

  config.configuration = new config.Configuration(projectName,
      cryptoTokensLocation:
          "${config.userHomePath}/Communications/CryptoTokens");

  var client = await auth.getAuthedClient();
  var dbService = new db.DatastoreDB(
      new datastore_impl.DatastoreImpl(client, "s~$projectName"));
  var sourceStorage = new storage.Storage(client, projectName);

  ss.fork(() async {
    storage.registerStorageService(sourceStorage);
    db.registerDbService(dbService);

    tasks.TaskController taskController = new tasks.TaskController(JOB_NAME);
    log.trace("Task loop starting");

    while (true) {
      var task = await taskController.getNextReadyTask();

      if (task == null) {
        log.info("Got null next ready task, sleeping");
        await new Future.delayed(DELAY_BETWEEN_TASK_POLLS);
        continue;
      }

      Stopwatch sw = new Stopwatch()..start();
      await _handleTask(task, JOB_NAME);
      log.perf("Task $task completed", sw.elapsedMilliseconds);
    }
  });
}


_handleTask(tasks.Task task, String jobName) async {
  log.trace("Starting task $task");
  Stopwatch sw = new Stopwatch()..start();

  try {
    await task.setState(tasks.LifecycleState.STARTED);

    log.trace("About to get source (${sw.elapsedMilliseconds}ms)");
    Map<String, String> source = await task.source;

    log.trace("About to get input (${sw.elapsedMilliseconds}ms)");
    String input = await task.input;

    log.trace("About to execute (${sw.elapsedMilliseconds}ms)");
    String response = await eval.eval(source, input);

    log.trace("Execution complete (${sw.elapsedMilliseconds}ms)");

    // TODO Handle the case where the result is too large to put in a
    // datastore entry

    log.trace("About to set result (${sw.elapsedMilliseconds}ms)");
    await task.setResult(response);

    await task.setState(tasks.LifecycleState.DONE);

  } catch (e, st) {
    log.info("Worker threw an exception: $e\n$st");
    await task.setResult("Worker threw an exception: $e\n$st");

    task.setState(tasks.LifecycleState.DEAD);
  }
}
