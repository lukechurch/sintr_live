// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the code that will be replaced by the infrastructure when
// the job is actually executed

import 'dart:async';
import 'dart:convert';

Future<String> sintrEntryPoint(String msg) async {
  Map<String, List<int>> kvList = JSON.decode(msg);
  String timeOfDay = kvList.keys.first;
  List<int> counts = kvList.values.first;
  int countsSum = counts.fold(0, (sum, a) => sum + a);

  return JSON.encode([
    {
      'timeOfDay': timeOfDay,
      'hogPresence': countsSum
    }
  ]);
}
