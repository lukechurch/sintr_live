// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the code that will be replaced by the infrastructure when
// the job is actually executed

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'file_getter.dart' as cloud_files;


Future<String> sintrEntryPoint(String msg) async {

  // Hack to detect file names
  if (msg.startsWith("hog-data/AccelData")) {
    cloud_files.setup();
    // It's a file, download and open it
    var path = await cloud_files.download("sintr-sample-test-data", msg.trim());
    msg = new File(path).readAsStringSync();
  }

  String text = msg.trim();
  print ("msg: $msg");

  var lines = text.split("\n");
  var kvs = [ ];
  int i = 0;
  for (var ln in lines) {
    print ("Line: $ln");
    var split = ln.split(" ");
    print ("split: ${split.length}");
    var timeStr = split[1];
    print (timeStr);

    var hour = timeStr.split(":")[0];
    print ("hour: $hour");

    var min = timeStr.split(":")[1];
    print ("min: $min");

    kvs.add(
    	{ "time" : "$hour-$min", "count" : 1}
      );
  }
  return JSON.encode(kvs);
}
