import 'dart:io' as io;
import 'dart:async';

import 'package:sintr_live_common/bucket_utils.dart' as bucket_utils;

import 'package:sintr_live_common/configuration.dart' as config;
import 'package:sintr_live_common/logging_utils.dart' as log;
import 'package:sintr_live_common/auth.dart' as auth;
import 'package:sintr_live_common/tasks.dart' as tasks;

import 'package:gcloud/db.dart' as db;
import 'package:gcloud/src/datastore_impl.dart' as datastore_impl;
import 'package:gcloud/storage.dart' as storage;
import 'package:gcloud/service_scope.dart' as ss;

const projectId = "sintr-994";

setup() async {
  log.setupLogging();
}

Future<String> download(String bucketName, String path) async {
  String dataPath = "${config.userHomePath}/sintr-data";

  // Setup cloud wrappers
  config.configuration = new config.Configuration(projectId,
      cryptoTokensLocation:
          "${config.userHomePath}/Communications/CryptoTokens");

  var dir = new io.Directory(dataPath);

  String targetPath = "${dir.path}/$path";

  if (!dir.existsSync()) dir.createSync(recursive: true);
  if (new io.File(targetPath).existsSync()) return targetPath;

  var client = await auth.getAuthedClient();
  var dbService = new db.DatastoreDB(
      new datastore_impl.DatastoreImpl(client, "s~$projectId"));
  var sourceStorage = new storage.Storage(client, projectId);

  await ss.fork(() async {
    storage.registerStorageService(sourceStorage);
    db.registerDbService(dbService);

    var stor = await new storage.Storage(client, projectId);
    var bucket = stor.bucket(bucketName);

    await bucket_utils.downloadFile(bucket, path, dir);
  });
  return targetPath;

}

main() async {
  setup();
  await download(
    "sintr-sample-test-data",
    "hog-data/AccelData_2016_01_27_16_44_24.log");
}
