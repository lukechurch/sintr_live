// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the code that will be replaced by the infrastructure when
// the job is actually executed

import 'dart:async';
import 'dart:convert';

// JSON coded Map<key, List<Value>> -> List<Map<Key', Value'>>

Future<String> sintrEntryPoint(String msg) async {
  Map kvList = JSON.decode(msg);
  List<Map<String, int>> result = [];
  var key = kvList.keys.first;
  var count = kvList.values.first.length;

  // var result = [];

  result.add(
    {
      "word" : key,
      "count" : count
    }
  );
  return JSON.encode(result);
}
