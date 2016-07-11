// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the mean local server to support the Sintr UI
// It is responsible for execution co-ordination

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

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

import 'mock_utils.dart'; // TODO: Remove these

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

  addCorsHeaders(request.response);

  log.trace("_handleRequest: ${request.uri}");
  if (request.uri.pathSegments.length == 0) {
    request.response..statusCode = 404
                    ..write("Available: taskStats, localExec, severExec, setNodeCount, taskStats")
                    ..close();
    return;
  }

  try {
    switch (request.method) {
      case "GET":
        await _handleGet(request);
        break;
      case "POST":
        await _handlePost(request);
        break;
      default:
        request.response..statusCode = 404 // TODO: Probably the wrong code
          ..write("Unknown method ${request.method}")
          ..close();
    }
  } catch (e, st) {
    request.response.statusCode = 500;
    request.response.writeln('$e \n $st');
  }
  await request.response.close();



}


_handleGet(io.HttpRequest request) async {
  io.HttpResponse res = request.response;

  String path = request.uri.path;
  switch (path) {
    case "/taskStats":
      res.write(await _getTaskStatus());
      break;

/*  =======================================
    LEGACY GET METHODS FROM THE MOCK SERVER
    TODO: These should be progressively removed
*/

case '/sampleInput':
  res.add(UTF8.encode(JSON.encode(sampleInput)));
  res.close();
  break;
case '/sources':
  Map<String, String> sources = {};
  sources["pubspec.yaml"] = PUBSPEC_SRC;
  sources["entry.dart"] = SRC;
  res.add(UTF8.encode(JSON.encode(sources)));
  res.close();
  break;
case '/nodesStatus':
  var nodesStatus = {'ready': 0, 'active': 0};
  if (responsePart == 0) {
    nodesStatus['active'] = 0;
    nodesStatus['ready'] = nodes;
  } else if (responsePart < nodesStatusStartSlope) {
    nodesStatus['active'] = nodes * responsePart ~/ nodesStatusStartSlope;
    nodesStatus['ready'] = nodes - nodesStatus['active'];
  } else if (responsePart > totalResponseParts - nodesStatusEndSlope) {
    var remainingResponseParts = totalResponseParts - responsePart;
    nodesStatus['active'] = nodes * remainingResponseParts ~/ nodesStatusEndSlope;
    nodesStatus['ready'] = nodes - nodesStatus['active'];
  } else {
    nodesStatus['active'] = nodes - 5 + rand.nextInt(5);
    nodesStatus['ready'] = nodes - nodesStatus['active'];
  }
  res.add(UTF8.encode(JSON.encode(nodesStatus)));
  res.close();
  break;
case '/tasksStatus':
  var tasksStatus = {'ready': 0, 'active': 0, 'done': 0, 'failed': 0};
  if (responsePart == 0 && taskDone == false) {
    tasksStatus['ready'] = tasksCount;
  } else if (responsePart == 0 && taskDone == false) {
    tasksStatus['done'] = tasksCount;
  } else {
    tasksStatus['active'] = tasksCount * responsePart ~/ totalResponseParts;
    tasksStatus['ready'] = tasksCount - tasksStatus['active'];
    if (tasksStatus['active'] > nodes) {
      tasksStatus['done'] = tasksStatus['active'] - nodes;
      tasksStatus['active'] = nodes;
    }
  }
  res.add(UTF8.encode(JSON.encode(tasksStatus)));
  res.close();
  break;
case '/isDone':
  if (responsePart == totalResponseParts) {
    // Mock up the need for multiple requests to get all data
    res.add(UTF8.encode("DONE"));
    res.close();
    taskDone = true;
    responsePart = 0;
  } else {
    // Mock up the need for multiple requests to get all data
    res.add(UTF8.encode("NOPE"));
    res.close();
  }
  break;
case "/results":
  var dataToSend = results[responsePart];
  res.add(UTF8.encode(JSON.encode(dataToSend)));
  res.close();
  responsePart++;
  break;


/*  =======================================
*/


    default:
      request.response.statusCode = 404;
    }
}

_handlePost(io.HttpRequest request) async {
  String path = request.uri.path;
  var requestString = await request.transform(UTF8.decoder).join();
  var json = JSON.decode(requestString);

  switch (path) {
    case "/localExec":
      Map<String, String> sources = json["sources"];
      String input = json["input"];
      if (sources == null) throw "sources missing";
      if (input == null) throw "input missing";

      String response = await _localExecuteMap(input, sources);
      request.response.write(response);
      break;

    case "/localReducer":
      Map<String, String> sources = json["sources"];
      String input = json["input"];
      if (sources == null) throw "sources missing";
      if (input == null) throw "input missing";

      String response = await _localExecuteReducer(input, sources);
      request.response.write(response);
      break;

    case "/severExec":
      Map<String, String> sources = json["sources"];
      List<String> input = json["input"];
      String jobName = json["jobName"];
      if (sources == null) throw "sources missing";
      if (input == null) throw "input missing";
      if (jobName == null) throw "jobName missing";

      if (noCloudProject) throw "Cannot remote execute without a cloud project";

      String response = await _serverExecuteMap(input, sources, jobName);
      request.response.write(response);
      break;

    case "/getResults":
      String jobName = json["jobName"];
      if (jobName == null) throw "jobName missing";
      if (noCloudProject) throw "Cannot get results without a cloud project";
      List<String> responses = await _getResults(jobName);
      request.response.write(JSON.encode(responses));
      break;

    case "/setNodeCount":
      int count = json["count"];
      if (count == null) throw "count missing";
      if (noCloudProject) throw "Cannot set node count without a cloud project";
      String response = await _setWorkerNodeCount(count);
      request.response.write(response);
      break;
    case "/taskStats":
      if (noCloudProject) throw "Cannot get task status without a cloud project";
      request.response.write(await _getTaskStatus());
      break;
    default:
      request.response.statusCode = 404;
  }
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



/**
 * Add Cross-site headers to enable accessing this server from pages
 * not served by this server
 *
 * See: http://www.html5rocks.com/en/tutorials/cors/
 * and http://enable-cors.org/server.html
 */
void addCorsHeaders(io.HttpResponse res) {
  res.headers.add("Access-Control-Allow-Origin", "*");
  res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.headers.add("Access-Control-Allow-Headers",
      "Origin, X-Requested-With, Content-Type, Accept");
}



// Legacy constants

final SRC = """
import 'dart:math';

int hogPresenceThreshold = 5.0;

Map<int, bool> map(String filename) {
  List<List<String>> tokens = await tokenizeFileByLines(filename);
  Map<int, bool> hogPresence = {};
  tokens.forEach((line) {
    var timestamp = int.parse(line[0]);
    var gx = double.parse(line[1]);
    var gy = double.parse(line[2]);
    var gz = double.parse(line[3]);
    var magnitude = sqrt(gx * gx + gy * gy + gz * gz);
    if (magnitude > hogPresenceThreshold) {
      hogPresence[timestamp] = true;
    } else {
      hogPresence[timestamp] = false;
    }
  });
  return hogPresence;
}

Map<bool, int> reduce(Map<int, bool> timestampPresence, Map<bool, int> partialCounts) {
  timestampPresence.forEach((int timestamp, bool presence) {
    partialCounts[presence] = partialCounts[presence] + 1;
  });
  return partialCounts;
}
""";

final PUBSPEC_SRC = """
name: 'sintr_ui'
version: 0.0.1
description: sample

environment:
  sdk: '>=1.0.0 <2.0.0'

dependencies:
  uuid: '>=0.5.0 <0.6.0'

""";


// Legacy variables

int responsePart = 0;
int totalResponseParts = results.length;
int nodesStatusStartSlope = 3;
int nodesStatusEndSlope = 10;
int tasksStatusStartSlope = 7;
int nodes = 500;
int tasksCount = 4000;
bool taskDone = false;
Random rand = new Random();
