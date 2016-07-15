// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is responsible for accepting the results of a map oepration
// and structuring it ready to be passed to the reducer

// This version performs the shuffling in memory and so is a potential scaling
// bottleneck
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

_main() {
  print (shuffle([{"a" : 1}, {"b" : 2}, {"a" : 2}]));
}
