// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

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

  if (args.length != 2) {
    print ("Usage: Startup cloud_project_id port");
    io.exit(1);
  }

  String projectName = args[0];
  int port = int.parse(args[1]);

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

    var requestServer =
        await io.HttpServer.bind(io.InternetAddress.LOOPBACK_IP_V4, port);
    log.info('listening on localhost, port ${requestServer.port}');

    await for (io.HttpRequest request in requestServer) {
      await _handleRequest(request);
    }
  });
}

_handleRequest(io.HttpRequest request) async {
  Stopwatch sw = new Stopwatch()..start();

  var requestString = await request.transform(UTF8.decoder).join();
  var json = JSON.decode(requestString);

  Map<String, String> source = json["sources"];
  String input = json["input"];

  log.trace("About to execute (startup._handleTask: ${sw.elapsedMilliseconds}ms)");
  String response = await eval.eval(source, input);
  log.trace("Response: $response (startup._handleTask: ${sw.elapsedMilliseconds}ms)");

  request.response..write(response)
                  ..close();
}
