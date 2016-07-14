// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the code that will be replaced by the infrastructure when
// the job is actually executed

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<String> sintrEntryPoint(String msg) async {
  String text = msg;
  List<Map<String, num>> kvs = [];

  text.split('\n').forEach((String line) {
    if (line.isEmpty) return;
    List<String> tokens = line.split(' ');
    DateTime timestamp = new DateTime.fromMillisecondsSinceEpoch(int.parse(tokens[2]));
    int hour = timestamp.hour;
    double accelerationX = double.parse(tokens[5]);
    double accelerationY = double.parse(tokens[8]);
    double accelerationZ = double.parse(tokens[11]);
    double gyroX = double.parse(tokens[15]);
    double gyroY = double.parse(tokens[18]);
    double gyroZ = double.parse(tokens[21]);
    double magnetX = double.parse(tokens[25]);
    double magnetY = double.parse(tokens[28]);
    double magnetZ = double.parse(tokens[31]);
    double temperature = double.parse(tokens[34]);
    double humidity = double.parse(tokens[36]);
    double pressure = double.parse(tokens[38]);
    kvs.add({
      'hour': hour,
      'accelerationX': accelerationX,
      'accelerationY': accelerationY,
      'accelerationZ': accelerationZ,
      'gyroX': gyroX,
      'gyroY': gyroY,
      'gyroZ': gyroZ,
      'magnetX': magnetX,
      'magnetY': magnetY,
      'magnetZ': magnetZ,
      'temperature': temperature,
      'humidity': humidity,
      'pressure': pressure,});
  });

  return JSON.encode(kvs);
}
