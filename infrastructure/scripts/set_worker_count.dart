// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Run from the root of the sintr_live checkout
// Generally this should be used via the set_worker_count.sh script

import 'dart:io';
import 'dart:async';
import 'dart:convert';

var resultString = "";
var resultErr = "";
var resultsDataJson;
var resultsFiltered = [];
const POLL_DELAY = const Duration(seconds: 5);

const ZONE_LIST = const [
  "us-central1-a",
  "us-east1-b",
  "asia-east1-a",
  "europe-west1-b"
];

String projectID = null;

main(List<String> args) async {
  if (args.length != 2) {
    print ("Usage: monitor.dart project-id count");
    exit(1);
  }
  projectID = args[0];
  int targetCount = int.parse(args[1]);

  for (String zone in ZONE_LIST) {
    log ("Processing zone: $zone");
    List<String> nodes = await getNodes(zone);

    log ("Node Count: ${nodes.length}, targetCount: $targetCount");


    if (nodes.length == targetCount) {
      log ("Right number of nodes in $zone");
      continue;
    }

    if (nodes.length > targetCount) {
      int countToDelete = nodes.length - targetCount;
      await deleteNodes(zone, nodes.sublist(0, countToDelete));
    } else {
      int countToStart = targetCount - nodes.length;
      await startNodes(zone, countToStart);
    }
    log ("Finished zone: $zone");
  }
}

log(String data) {
  print ("${new DateTime.now()}: $data");
}


Future<List<String>> getNodes(String zone) async {
  var results =
    await Process.run("gcloud",
      ['compute', 'instances', 'list',
      '--format', 'json',
      '--zone', zone,
      '--project', projectID]);

  resultString = results.stdout;
  resultErr = results.stderr;

  List resultsDataJson = JSON.decode(resultString);
  return resultsDataJson.map((f) => f["name"]).toList();
}

Future startNodes(String zone, int count) async {
  log ("Starting: $count nodes in $zone");
  var results =
    await Process.run("bash",
      ["infrastructure/scripts/start_nodes.sh", projectID, zone, "$count"]);

  resultString = results.stdout;
  resultErr = results.stderr;
  log ("Start completed: stdout:\n $resultString stdErr:\n $resultErr");
}

Future deleteNodes(String zone, List<String> nodeNames) async {
  log ("Deleting: ${nodeNames.length} in $zone");
  log ("Nodes to be deleted: ${nodeNames}");


  List commandArgs = ['compute', 'instances', 'delete'];
  commandArgs.addAll(nodeNames);
  commandArgs.addAll([
    '--zone', zone,
    '--project', projectID]);

  var results = await Process.run("gcloud", commandArgs);

  resultString = results.stdout;
  resultErr = results.stderr;
  log ("Delete completed: stdout:\n $resultString stdErr:\n $resultErr");
}
