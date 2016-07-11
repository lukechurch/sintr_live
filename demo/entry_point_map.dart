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

  List<String> words = text.split(" ");
  List<Map<String, int>> kvs = [];

  int i = 0;

  for (String word in words) {
    if (++i % 100000 == 0) break;
    kvs.add({word: 1});
  }

  return JSON.encode(kvs);
}
