// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the code that will be replaced by the infrastructure when
// the job is actually executed

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<String> sintrEntryPoint(String msg) async {
  List<Map<String, num>> kvsInput = JSON.decode(msg);
  List<Map<String, num>> kvsOutput = [];
  // This is the shuffler
  Map<String, List> dataByHour = {};
  kvsInput.forEach((Map<String, num> kv) {
    String hour = kv['hour'].toString();
    dataByHour.putIfAbsent(hour, () => []);
    dataByHour[hour].add(kv);
  });

  dataByHour.forEach((String hour, List<Map<String, num>> data) {
    double accelerationXSum = 0.0;
    double accelerationYSum = 0.0;
    double accelerationZSum = 0.0;
    double gyroXSum = 0.0;
    double gyroYSum = 0.0;
    double gyroZSum = 0.0;
    double magnetXSum = 0.0;
    double magnetYSum = 0.0;
    double magnetZSum = 0.0;
    double temperatureSum = 0.0;
    double humiditySum = 0.0;
    double pressureSum = 0.0;
    data.forEach((Map<String, num> dataPoint) {
      accelerationXSum += dataPoint['accelerationX'];
      accelerationYSum += dataPoint['accelerationY'];
      accelerationZSum += dataPoint['accelerationZ'];
      gyroXSum += dataPoint['gyroX'];
      gyroYSum += dataPoint['gyroY'];
      gyroZSum += dataPoint['gyroZ'];
      magnetXSum += dataPoint['gyroX'];
      magnetYSum += dataPoint['gyroY'];
      magnetZSum += dataPoint['gyroZ'];
      temperatureSum += dataPoint['temperature'];
      humiditySum += dataPoint['humidity'];
      pressureSum += dataPoint['pressure'];
    });
    kvsOutput.add({
      'hour': hour,
      'accelerationX': accelerationXSum / data.length,
      'accelerationY': accelerationYSum / data.length,
      'accelerationZ': accelerationZSum / data.length,
      'gyroX': gyroXSum / data.length,
      'gyroY': gyroYSum / data.length,
      'gyroZ': gyroZSum / data.length,
      'magnetX': magnetXSum / data.length,
      'magnetY': magnetYSum / data.length,
      'magnetZ': magnetZSum / data.length,
      'temperature': temperatureSum / data.length,
      'humidity': humiditySum / data.length,
      'pressure': pressureSum / data.length,
    });
  });
  return JSON.encode(kvsOutput);
}
