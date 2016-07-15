// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the code that will be replaced by the infrastructure when
// the job is actually executed

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<String> sintrEntryPoint(String msg) async {
  List<Map<String, int>> kvsInput = JSON.decode(msg);
  Map<String, List<int>> shuffledInput = shuffle(kvsInput);
  List<Map<String, int>> kvsOutput = [];

  shuffledInput.forEach((String timeOfDay, List<int> values) {
    Map<String, int> kv = {'timeOfDay': timeOfDay, 'hogPresence': 0};
    values.forEach((int value) {
        kv['hogPresence'] += value;
    });
    kvsOutput.add(kv);
  });

  return JSON.encode(kvsOutput);
}

Map shuffle(List<Map> data) {
  Map results = {};
  for (Map kv in data) {
    assert(kv.length == 1);
    var key = kv.keys.first;
    var value = kv.values.first;

    results.putIfAbsent(key, () => []);
    results[key].add(value);
  }
  return results;
}
