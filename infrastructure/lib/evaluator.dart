// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is responsible for taking a source dictionary and returning the
// results of the execution


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:sintr_live_infrastructure/_isolate_main.dart';

import 'package:sintr_live_common/source_utils.dart' as src_utils;
import 'package:path/path.dart' as path;
import 'package:sintr_live_infrastructure/log.dart' as log;

SendPort sendPort;
ReceivePort receivePort;
Isolate isolate;

StreamController resultsController;
Stream resultsStream;

const MAX_SPIN_WAITS_FOR_SEND_PORT = 10000;
String _installedSourceSha = null;
String _installedPubSpec = null;

const SINTR_WORKING_PATH = "sintr-working-clientcode";
const ISOLATE_STARTUP_NAME = "_isolate_main.dart";
Directory workingDirectory = null;
String workingPath = null;

Future<String> eval(Map<String, String> source, String message) async {
  Stopwatch sw = new Stopwatch()..start();

  log.trace("about to _prepareSetup (${sw.elapsedMilliseconds}ms)");
  _prepareSetup();
  log.trace("_prepareSetup done, about to _installSource (${sw.elapsedMilliseconds}ms)");
  _installSource(source);
  log.trace("_installSource done, about to _resetWorker (${sw.elapsedMilliseconds}ms)");
  _resetWorker("Always reset policy");
  log.trace("_resetWorker done, about to _resetWorker (${sw.elapsedMilliseconds}ms)");
  await _setupIsolate(path.join(workingPath, ISOLATE_STARTUP_NAME));

  log.trace("Sending: $message (${sw.elapsedMilliseconds}ms)");
  sendPort.send(message);

  String response = await resultsStream.first;
  log.debug("Response: $response (${sw.elapsedMilliseconds}ms)");

  return response;
}

_prepareSetup() {
  String homeDir = Platform.environment["HOME"];
  workingPath = path.join(homeDir, SINTR_WORKING_PATH);
  workingDirectory = new Directory(workingPath);

  if (!workingDirectory.existsSync()) workingDirectory.createSync(recursive: true);
}

_installSource(Map<String, String> source) {
  String sha = src_utils.computeCodeSha(source);
  if (_installedSourceSha == sha) {
    log.trace("Sha match, no source changes: $sha");
    return;
  }

  // Write the source to disk - note that in this case it doesn't do clean up
  List<String> pubspecPathsToUpdate = <String>[];

  for (String sourceName in source.keys) {

    String fullName = path.join(workingPath, sourceName);
    File fileObj = new File(fullName);

    if (sourceName.toLowerCase().endsWith("pubspec.yaml")) {
      if (fileObj.existsSync() &&
          fileObj.readAsStringSync() == source[sourceName]) {
        log.trace("$fullName unchanged, skipping");
        continue; // Pubspec on disk was exactly the same as in memory
      } else {
        log.trace("$fullName changed, Pub get will be needed");
        pubspecPathsToUpdate.add(fullName);
      }
    }

    log.trace("Writing: ${fileObj.path}");
    // Ensure that the folder structures are in place
    fileObj.createSync(recursive: true);
    fileObj.writeAsStringSync(source[sourceName]);
  }

  // Write the isolate startup handler
  String startupLocation = path.join(workingPath, ISOLATE_STARTUP_NAME);
  new File(startupLocation).writeAsStringSync(ISOLATE_MAIN_CODE);

  if (pubspecPathsToUpdate.length > 0) _pubUpdate(pubspecPathsToUpdate);
}

_pubUpdate(List<String> pubspecPathsToUpdate) async {
  log.trace("_pubUpdate called for: \n${pubspecPathsToUpdate.join('\n')}");

  Directory orginalWorkingDirectory = Directory.current;

  for (String fullName in pubspecPathsToUpdate) {
    Directory.current = path.dirname(fullName);

    log.trace("In ${Directory.current.toString()} about to run pub get");
    ProcessResult result = await Process.runSync("pub", ["get"]);
    log.trace("Pub get complete: exit code: ${result.exitCode} \n"
        " stdout:\n${result.stdout} \n stderr:\n${result.stderr}");
  }
  Directory.current = orginalWorkingDirectory;
}

_setupIsolate(String startPath) async {
  log.debug("isolate == null: ${isolate == null}");
  log.debug("_setupIsolate: $startPath");
  sendPort = null;
  receivePort = new ReceivePort();
  resultsController = new StreamController();
  resultsStream = resultsController.stream.asBroadcastStream();

  log.debug("About to bind to recieve port");
  receivePort.listen((msg) {
    log.trace("recievePort message: $msg");

    if (sendPort == null) {
      log.debug("send port recieved");
      sendPort = msg;
    } else {
      resultsController.add(msg);
    }
  });
  log.debug("About to spawn isolate");
  isolate =
      await Isolate.spawnUri(
        Uri.parse(startPath),
        [],
        receivePort.sendPort,
        errorsAreFatal: false,
      automaticPackageResolution : true);
  log.debug("Isolate spawned");
  int spinCounter = 0;
  while (sendPort == null && spinCounter++ < MAX_SPIN_WAITS_FOR_SEND_PORT) {
    log.debug("About to poll wait: $spinCounter");
    await new Future.delayed(new Duration(milliseconds: 1));
    log.debug("Spinning waiting for send port: $spinCounter");
  }

  if (sendPort == null) {
    throw "sendPort was not recieved after $MAX_SPIN_WAITS_FOR_SEND_PORT waits";
  }
  log.info("Worker isolate spawned");
}

_resetWorker(String cause) async {
  log.debug("Restarting isolate due to: $cause");
  log.debug("About to kill, isolate == null: ${isolate == null}");
  isolate?.kill(priority: Isolate.IMMEDIATE);
  isolate = null;

  log.debug("ResultsStream == null: ${resultsStream == null}");
  resultsController?.close();
  await resultsStream?.drain();
  log.debug("Isolate now null");
}
