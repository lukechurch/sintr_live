// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the code that will be replaced by the infrastructure when
// the job is actually executed

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'file_getter.dart' as cloud_files;

// String -> List<Map<Key, Value>>

Future<String> sintrEntryPoint(String msg) async {
    // Hack to detect file names
  if (msg.startsWith("hog-data/AccelData")) {
    cloud_files.setup();
    // It's a file, download and open it
    var path = await cloud_files.download("sintr-sample-test-data", msg.trim());
    msg = new File(path).readAsStringSync();
  }

  String text = msg;
  List<Map<String, dynamic>> varianceData = [];

  text.split('\n').forEach((String line) {
    processLogLine(line, varianceData);
  });
	emitResults(varianceData);

  num intervalSizeInSeconds = 600;
  num movementThresholdGyroX = 0.25;
  num movementThresholdGyroY = 0.15;
  num movementThresholdGyroZ = 0.025;

  Map<int, int> intervalMap = {}; // period and count of movements above a threshold
  varianceData.forEach((Map<String, dynamic> kv) {

    int correspondingInterval = (kv['secondsSinceEpoch'] / intervalSizeInSeconds).floor();
    intervalMap.putIfAbsent(correspondingInterval, () => 0);

    if (kv['varianceGyroX'] > movementThresholdGyroX ||
        kv['varianceGyroY'] > movementThresholdGyroY ||
        kv['varianceGyroZ'] > movementThresholdGyroZ) {
      // This means it's quite a bit of variance, so hedgehog likely.
      intervalMap[correspondingInterval] += 1;
    }
  });

  List<Map<String, Map>> kvs = [];
  intervalMap.forEach((int intervalStart, int count) {
    DateTime time = new DateTime.fromMillisecondsSinceEpoch(intervalStart * intervalSizeInSeconds * 1000);
    kvs.add({
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}': count
    });
  });

  return JSON.encode(kvs);
}


// Log processing code which extracts gyro variance over groups of
// [BUCKET_WINDOW] seconds.
// From https://dartpad.dartlang.org/2bd728111e8ebe0d0dda
const int BUCKET_WINDOW = 5;
const GYRO_X = "gryox";
const GYRO_Y = "gryoy";
const GYRO_Z = "gryoz";
const TEMP = "temp";
const HUMIDITY = "humidity";

Map<String, List<num>> bucketData = {};
int bucketStartTime = -1;

processLogLine(String line, List<Map> output) {
  var dataItems = line.split(" ");
  if (dataItems.length != 39) return;
  var timeSinceEpoch = int.parse(dataItems[2]);
  var gyroX = double.parse(dataItems[15]);
  var gyroY = double.parse(dataItems[18]);
  var gyroZ = double.parse(dataItems[21]);
  var temp = double.parse(dataItems[34]);
  var humidity = double.parse(dataItems[36]);
  int seconds = (timeSinceEpoch / 1000).floor();

  int bucketTime = (seconds / BUCKET_WINDOW).floor();
  if (bucketTime != bucketStartTime) {
    if (bucketStartTime != -1) emitResults(output);
    bucketData = {GYRO_X: [], GYRO_Y: [], GYRO_Z: [], TEMP : [], HUMIDITY : []};
    bucketStartTime = bucketTime;
  }

  bucketData[GYRO_X].add(gyroX);
  bucketData[GYRO_Y].add(gyroY);
  bucketData[GYRO_Z].add(gyroZ);
  bucketData[TEMP].add(temp);
  bucketData[HUMIDITY].add(humidity);
}

emitResults(List output) {
  Map point = {
    'secondsSinceEpoch': bucketStartTime * BUCKET_WINDOW,
    'time': new DateTime.fromMillisecondsSinceEpoch(bucketStartTime * BUCKET_WINDOW * 1000).toString(),
    'varianceGyroX': computeVariance(bucketData[GYRO_X]),
    'varianceGyroY': computeVariance(bucketData[GYRO_Y]),
    'varianceGyroZ': computeVariance(bucketData[GYRO_Z]),
  };
  if (point['varianceGyroX'] > 100 || point['varianceGyroY'] > 100 || point['varianceGyroZ'] > 100) {
    return;
  }
  output.add(point);
}

num computeMean(List<num> data) =>
  data.fold(0, (a, b) => a + b) / data.length;

num computeVariance(List<num> xs) {
  var xbar = computeMean(xs);
  num acc = 0;

  for (var x in xs) {
    num t = x - xbar;
    acc += (t * t);
  }
  return acc / xs.length;
}
