// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the code that will be replaced by the infrastructure when
// the job is actually executed

import 'dart:async';
import 'dart:convert';

Future<String> sintrEntryPoint(String msg) async {
  Map<String, List<int>> input = JSON.decode(msg);
  Map<String, int> kvMap = {};
  input.forEach((String word, List<int> counts) {
    int sum = counts.reduce((a, b) => a + b);
    kvMap.putIfAbsent(word, () => 0);
    kvMap[word] = kvMap[word] + sum;
  });

  List<Map<String, int>> result = [];
  kvMap.forEach((String word, int count) => result.add({'word': word, 'count': count}));
  return JSON.encode(result);
}
