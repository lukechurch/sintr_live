// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS('google.charts')
library google.charts;

import "package:js/js.dart";

@anonymous
@JS()
class GoogleChartsLoadOptions {
  external factory GoogleChartsLoadOptions(
    {List<String> packages}
  );
  external List<String> get packages;
  external set packages(List<String> v);
}

@JS()
external load(String version, GoogleChartsLoadOptions options);

@JS()
external setOnLoadCallback(Function f);
