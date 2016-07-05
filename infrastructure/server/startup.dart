// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the mean local server to support the Sintr UI
// It is responsible for execution co-ordination

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:sintr_live_common/configuration.dart' as config;
import 'package:sintr_live_common/logging_utils.dart' as log;
import 'package:sintr_live_common/auth.dart' as auth;
import 'package:sintr_live_common/tasks.dart' as tasks;
import 'package:sintr_live_infrastructure/evaluator.dart' as eval;

import 'package:sintr_live_infrastructure/worker_machines_utils.dart' as worker_utils;

import 'package:gcloud/db.dart' as db;
import 'package:gcloud/src/datastore_impl.dart' as datastore_impl;
import 'package:gcloud/storage.dart' as storage;
import 'package:gcloud/service_scope.dart' as ss;

const JOB_NAME = "sintr-live-interactive-job";

String projectId;

main(List<String> args) async {
  log.setupLogging();
  log.debug("Startup args: $args");

  if (args.length != 2) {
    print ("Usage: Startup cloud_project_id port");
    io.exit(1);
  }

  projectId = args[0];
  int port = int.parse(args[1]);

  // Setup cloud wrappers
  config.configuration = new config.Configuration(projectId,
      cryptoTokensLocation:
          "${config.userHomePath}/Communications/CryptoTokens");

  var client = await auth.getAuthedClient();
  var dbService = new db.DatastoreDB(
      new datastore_impl.DatastoreImpl(client, "s~$projectId"));
  var sourceStorage = new storage.Storage(client, projectId);

  ss.fork(() async {
    storage.registerStorageService(sourceStorage);
    db.registerDbService(dbService);

    var requestServer =
        await io.HttpServer.bind(io.InternetAddress.LOOPBACK_IP_V4, port);
    log.info('listening on localhost, port ${requestServer.port}');

    // Actually handle HTTP requests

    await for (io.HttpRequest request in requestServer) {
      await _handleRequest(request);
    }
  });
}

_handleRequest(io.HttpRequest request) async {
  Stopwatch sw = new Stopwatch()..start();

  log.trace("_handleRequest: $request");
  if (request.uri.pathSegments.length == 0) {
    request.response..statusCode = 404
                    ..write("Available: taskStats, localExec, severExec, setNodeCount, taskStats")
                    ..close();
    return;
  }
  String lastSegment = request.uri.pathSegments.last;
  log.trace("_handleRequest, lastSegment: $lastSegment");

  if (request.method.toLowerCase() == "get") {
    switch (lastSegment) {
      case "taskStats":
        request.response.write(await _getTaskStatus());
        break;
      default:
        request.response.statusCode = 404;
      }
    } else {
      var requestString = await request.transform(UTF8.decoder).join();
      var json = JSON.decode(requestString);

      switch (lastSegment) {
        case "localExec":
          Map<String, String> sources = json["sources"];
          String input = json["input"];
          String response = await _localExecuteMap(input, sources);
          request.response.write(response);
          break;

        case "severExec":
          Map<String, String> sources = json["sources"];
          List<String> input = json["input"];
          String response = await _serverExecuteMap(input, sources);
          request.response.write(response);
          break;

        case "setNodeCount":
          int count = json["count"];
          String response = await _setWorkerNodeCount(count);
          request.response.write(response);
          break;
        case "taskStats":
          request.response.write(await _getTaskStatus());
          break;
        default:
          request.response.statusCode = 404;
      }
    }
  await request.response.close();
}

/// Local execution of a map operation, returning the result
Future<String> _localExecuteMap(String msg, Map<String, String> sources) async {
  log.trace("_localExecuteMap: $msg");
  String response = await eval.eval(sources, msg);
  return new Future.value(response);
}

/// Map returning the task name that's associated with the map operation
Future<String> _serverExecuteMap(List<String> msg, Map<String, String> sources) async {
  log.trace("_serverExecuteMap: $msg");
  return new Future.value("Implement me");
}

Future _setWorkerNodeCount(int count) async {
  log.trace("_setWorkerNodeCount: $count");
  worker_utils.setWorkerCount(projectId, count);
  return new Future.value("Node count set");
}

Future<String> _getTaskStatus() async {
  log.trace("_getTaskStatus");
  tasks.TaskController taskController =
      new tasks.TaskController("example_task");
  var taskState = await taskController.queryTaskState();
  return "$taskState";
}
