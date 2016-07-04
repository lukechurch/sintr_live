import 'dart:io';
import 'package:sintr_live_infrastructure/evaluator.dart' as eval;
import 'package:sintr_live_common/task_utils.dart' as task_util;
import 'package:sintr_live_common/tasks.dart' as tasks;
import 'package:sintr_live_common/configuration.dart' as config;
import 'package:sintr_live_common/auth.dart';


import 'package:gcloud/db.dart' as db;
import 'package:gcloud/service_scope.dart' as ss;
import 'package:gcloud/src/datastore_impl.dart' as datastore_impl;
import 'package:gcloud/storage.dart' as storage;

import 'package:sintr_live_common/logging_utils.dart' as logging;

// Run this from the root of the sintr_live checkout

String JOB_NAME = "sintr-interactive";

main(List<String> args) async {
  if (args.length != 1) {
    print ("Usage: sample_run.dart project_id");
    exit(1);
  }

  String projectId = args[0];

  logging.setupLogging();

  config.configuration = new config.Configuration(projectId,
        cryptoTokensLocation:
            "${config.userHomePath}/Communications/CryptoTokens");

  var client = await getAuthedClient();
  var datastore = new datastore_impl.DatastoreImpl(client, 's~$projectId');
  var datastoreDB = new db.DatastoreDB(datastore);
  var cloudstore = new storage.Storage(client, projectId);

  logging.trace("Setup done");

  await ss.fork(() async {
    db.registerDbService(datastoreDB);



  String src = new File('infrastructure/lib/entry_point.dart').readAsStringSync();

  var sources = { "entry_point.dart" : src };
  var inputs = new List.generate(1000, (i) => "$i");//  //["0", "1", "2"];

  tasks.TaskController taskController = new tasks.TaskController(JOB_NAME);
  await taskController.createTasks(inputs, sources);

  print ("tasks created");

  // for (int i = 0; i < 1000; i++) {
    // print(await eval.eval( , "test-msg-$i"));
    // await eval.eval({ "entry_point.dart" : src } , "test-msg2");
  // }

  });
}
