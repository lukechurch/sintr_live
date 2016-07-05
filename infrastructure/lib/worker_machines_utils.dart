import 'dart:io';
import 'dart:async';
import 'dart:convert';

const ZONE_LIST = const [
  "us-central1-a",
  "us-east1-b",
  "asia-east1-a",
  "europe-west1-b"
];


setWorkerCount(String projectID, int targetCount) async {

  for (String zone in ZONE_LIST) {
    log ("Processing zone: $zone");
    List<String> nodes = await getNodes(projectID, zone);

    log ("Node Count: ${nodes.length}, targetCount: $targetCount");


    if (nodes.length == targetCount) {
      log ("Right number of nodes in $zone");
      continue;
    }

    if (nodes.length > targetCount) {
      int countToDelete = nodes.length - targetCount;
      await deleteNodes(projectID, zone, nodes.sublist(0, countToDelete));
    } else {
      int countToStart = targetCount - nodes.length;
      await startNodes(projectID, zone, countToStart);
    }
    log ("Finished zone: $zone");
  }
}

Future<List<String>> getNodes(String projectID, String zone) async {
  var results =
    await Process.run("gcloud",
      ['compute', 'instances', 'list',
      '--format', 'json',
      '--zone', zone,
      '--project', projectID]);

  var resultString = results.stdout;
  var resultErr = results.stderr;

  List resultsDataJson = JSON.decode(resultString);
  return resultsDataJson.map((f) => f["name"]).toList();
}

Future startNodes(String projectID, String zone, int count) async {
  log ("Starting: $count nodes in $zone");
  var results =
    await Process.run("bash",
      ["infrastructure/scripts/start_nodes.sh", projectID, zone, "$count"]);

  var resultString = results.stdout;
  var resultErr = results.stderr;
  log ("Start completed: stdout:\n $resultString stdErr:\n $resultErr");
}

Future deleteNodes(String projectID, String zone, List<String> nodeNames) async {
  log ("Deleting: ${nodeNames.length} in $zone");
  log ("Nodes to be deleted: ${nodeNames}");


  List commandArgs = ['compute', 'instances', 'delete'];
  commandArgs.addAll(nodeNames);
  commandArgs.addAll([
    '--zone', zone,
    '--project', projectID]);

  var results = await Process.run("gcloud", commandArgs);

  var resultString = results.stdout;
  var resultErr = results.stderr;
  log ("Delete completed: stdout:\n $resultString stdErr:\n $resultErr");
}


// TODO: Migrate to logging package
log(String data) {
  print ("${new DateTime.now()}: $data");
}
