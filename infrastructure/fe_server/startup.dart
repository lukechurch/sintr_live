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

/*
 * This starts a general purpose front end server that can handle
 * local evaluation, remote evaluation, and querying properties of the
 * infrastructure
 */

String projectId;
bool noCloudProject = false;

main(List<String> args) async {
  log.setupLogging();
  log.debug("Startup args: $args");

  if (args.length != 2) {
    print ("Usage: Startup cloud_project_id port");
    print ("If you wish to use the fe_server for local usage only");
    print ("use - for the cloud_project_id");
    io.exit(1);
  }

  projectId = args[0];
  if (projectId.trim() == "-") {
    log.info("Starting fe_server for local usage only");
    noCloudProject = true;
  } else {
    log.info("Starting fe_server with cloud project $projectId");
  }
  int port = int.parse(args[1]);

  // Local only startup
  if (noCloudProject) {
    _serverStartup(port);
    return;
  }

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

    await _serverStartup(port);
  });
}

_serverStartup(int port) async {
  var requestServer =
      await io.HttpServer.bind(io.InternetAddress.LOOPBACK_IP_V4, port);
  log.info('listening on localhost, port ${requestServer.port}');

  // Actually handle HTTP requests

  await for (io.HttpRequest request in requestServer) {
    await _handleRequest(request);
  }
}

_handleRequest(io.HttpRequest request) async {
  // Stopwatch sw = new Stopwatch()..start();

  log.trace("_handleRequest: $request");
  if (request.uri.pathSegments.length == 0) {
    request.response..statusCode = 404
                    ..write("Available: taskStats, localExec, severExec, setNodeCount, taskStats")
                    ..close();
    return;
  }
  String lastSegment = request.uri.pathSegments.last;
  log.trace("_handleRequest, lastSegment: $lastSegment");

  try {
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

          case "localReducer":
            Map<String, String> sources = json["sources"];
            String input = json["input"];
            String response = await _localExecuteReducer(input, sources);
            request.response.write(response);
            break;

          case "severExec":
            Map<String, String> sources = json["sources"];
            List<String> input = json["input"];
            String jobName = json["jobName"];
            String response = await _serverExecuteMap(input, sources, jobName);
            request.response.write(response);
            break;

          case "getResults":
            String jobName = json["jobName"];
            List<String> responses = await _getResults(jobName);
            request.response.write(JSON.encode(responses));
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
  } catch (e, st) {
    request.response.statusCode = 500;
    request.response.writeln('$e \n $st');
  }
  await request.response.close();
}

/// Local execution of a map operation, returning the result
Future<String> _localExecuteMap(String msg, Map<String, String> sources) async {
  log.trace("_localExecuteMap: $msg");
  String response = await eval.eval(sources, msg);
  return new Future.value(response);
}

Future<String> _localExecuteReducer(String msg, Map<String, String> sources) async {
  log.trace("_localExecuteReducer: $msg");
  String response = await eval.eval(sources, msg);
  return new Future.value(response);
}

/// Map returning the task name that's associated with the map operation
Future<String> _serverExecuteMap(
  List<String> msgs,
  Map<String, String> sources,
  String jobName) async {
  log.trace("_serverExecuteMap: $msgs");

  if (noCloudProject) {
    log.alert("No Cloud project configured, remote execution unavailable");
    throw "No cloud project";
  }

  tasks.TaskController taskController = new tasks.TaskController(jobName);
  await taskController.createTasks(msgs, sources);
  return new Future.value("Tasks created");
}

Future<List<String>> _getResults(String jobName) {
  log.trace("_getResults: $jobName");

  if (noCloudProject) {
    log.alert("No Cloud project configured, get results unavailable");
    throw "No cloud project";
  }

  tasks.TaskController taskController = new tasks.TaskController(jobName);
  return taskController.queryResultsForJob();
}

Future _setWorkerNodeCount(int count) async {
  log.trace("_setWorkerNodeCount: $count");

  if (noCloudProject) {
    log.alert("No Cloud project configured, _setWorkerNodeCount unavailable");
    throw "No cloud project";
  }

  worker_utils.setWorkerCount(projectId, count);
  return new Future.value("Node count set");
}

Future<String> _getTaskStatus() async {
  log.trace("_getTaskStatus");

  if (noCloudProject) {
    log.alert("No Cloud project configured, _getTaskStatus unavailable");
    throw "No cloud project";
  }

  tasks.TaskController taskController =
      new tasks.TaskController("example_task");
  var taskState = await taskController.queryTaskState();
  return "$taskState";
}
