// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

trace(String item) => _log("TRACE: $item");
info(String item) => _log("INFO: $item");
debug(String item) => _log("DEBUG: $item");

_log(String item) {
  var dt = new DateTime.now();
  print ("$dt $item");
}
