// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS('google.visualization')
library google.visualization;

import 'dart:html';

import "package:js/js.dart";

@anonymous
@JS()
external DataTable arrayToDataTable(List array);

@anonymous
@JS()
class ColumnDescription {
  external factory ColumnDescription(
    {String type,
    String label,
    String id,
    String role,
    String pattern});
  external String get type;
  external set type(String v);
  external String get label;
  external set label(String v);
  external String get id;
  external set id(String v);
  external String get role;
  external set role(String v);
  external String get pattern;
  external set pattern(String v);
}

@anonymous
@JS()
class DataTable {
  external DataTable([data, num version]);
  // external num addColumn(String type, [String label, String id]);
  external num addColumn(ColumnDescription description);
  external num addRow([List cellArray]);
  external num addRows(numOrArray);
  external void removeColumn(int columnIndex);
  external void removeColumns(int columnIndex, int numberOfColumns);
  external void removeRow(int rowIndex);
  external void removeRows(int rowIndex, int numberOfRows);
  external void setCell(int rowIndex, int columnIndex, [value, formattedValue, properties]);
}

@anonymous
@JS()
class ChartAreaOptions {
  external factory ChartAreaOptions(
    {String width}
  );
  external String get width;
  external set width(String v);
}

@anonymous
@JS()
class AnimationOptions {
  external factory AnimationOptions(
    {int duration,
    String easing,
    bool startup}
  );
  /// The duration of the animation, in milliseconds. For details, see the
  /// [animation documentation](https://developers.google.com/chart/interactive/docs/animation).
  ///
  /// Default: 0
  external int get duration;
  external set duration(int v);

  /// The easing function applied to the animation. The following options are
  /// available:
  /// * 'linear' - Constant speed.
  /// * 'in' - Ease in - Start slow and speed up.
  /// * 'out' - Ease out - Start fast and slow down.
  /// * 'inAndOut' - Ease in and out - Start slow, speed up, then slow down.
  ///
  /// Default: 'linear'
  external String get easing;
  external set easing(String v);

  /// Determines if the chart will animate on the initial draw. If true,
  /// the chart will start at the baseline and animate to its final state.
  ///
  /// Default: false
  external bool get startup;
  external set startup(bool v);
}

@anonymous
@JS()
class AnnotationsOptions {
  external factory AnnotationsOptions(
    {bool alwaysOutside

    }
  );
}

@anonymous
@JS()
class ViewWindowOptions {
  external factory ViewWindowOptions(
    {int min, int max}
  );
  external int get min;
  external set min(int v);
  external int get max;
  external set max(int v);
}

@anonymous
@JS()
class HAxisOptions {
  external factory HAxisOptions(
    {String title,
      int minValue,
      ViewWindowOptions viewWindow,
      String textPosition}
  );
  external String get title;
  external set title(String v);
  external int get minValue;
  external set minValue(int v);
  external ViewWindowOptions get viewWindow;
  external set viewWindow(ViewWindowOptions v);
  external String get textPosition;
  external set textPosition(String v);
}


@anonymous
@JS()
class VAxisOptions {
  external factory VAxisOptions(
    {String title,
      int minValue,
      int maxValue}
  );
  external String get title;
  external set title(String v);
  external int get minValue;
  external set minValue(int v);
  external int get maxValue;
  external set maxValue(int v);
}


@anonymous
@JS()
class BarOptions {
  external factory BarOptions(
    {String groupWidth}
  );
  external String get groupWidth;
  external set title(String groupWidth);
}

@anonymous
@JS()
class DrawOptions {
  external factory DrawOptions({
    String title,
    ChartAreaOptions chartArea,
    dynamic isStacked, // can be a bool or a string
    String legend,
    AnimationOptions animation,
    HAxisOptions hAxis,
    BarOptions bar,
    VAxisOptions vAxis,
    String orientation
  });

  external String get title;
  external set title(String v);
  external ChartAreaOptions get chartArea;
  external set chartArea(ChartAreaOptions v);
  external dynamic get isStacked;
  external set isStacked(dynamic v);
  external String get legend;
  external set legend(String v);
  external AnimationOptions get animation;
  external set animation(AnimationOptions v);
  external HAxisOptions get hAxis;
  external set hAxis(HAxisOptions v);
  external BarOptions get bar;
  external set bar(BarOptions v);
  external VAxisOptions get vAxis;
  external set vAxis(VAxisOptions v);
  external String get orientation;
  external set orientation(String v);
}

@anonymous
@JS()
class BarChart {
  external BarChart(Element e);
  external draw(DataTable data, DrawOptions options);
}

@anonymous
@JS()
class PieChart {
  external PieChart(Element e);
  external draw(DataTable data, DrawOptions options);
}

@anonymous
@JS()
class AreaChart {
  external AreaChart(Element e);
  external draw(DataTable data, DrawOptions options);
}
