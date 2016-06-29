// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS IS A DUMMY FILE DO NOT EDIT
// This is the code that will be replaced by the infrastructure when
// the job is actually executed

import 'dart:async';

Future<String> sintrEntryPoint(String msg) async {
  // throw "Please replace the entry point";
  await new Duration(milliseconds: 5000);
  return "Sample string-$msg";
}
