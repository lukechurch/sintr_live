// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sintr_ui;

// Variables that control the visualisation.
const statesColorMap = const {
  'ready': '#3C94F2', // blue
  'active': '#33AF28', // green
  'done': '#F4EF5D', // yellow
  'failed': '#962D2D', // red
};

Map statesStyleMap = {
  'ready':  'stroke-color: ${statesColorMap["ready"]};  stroke-width: 1; fill-color: ${statesColorMap["ready"]}',
  'active': 'stroke-color: ${statesColorMap["active"]}; stroke-width: 1; fill-color: ${statesColorMap["active"]}',
  'done':   'stroke-color: ${statesColorMap["done"]};   stroke-width: 1; fill-color: ${statesColorMap["done"]}',
  'failed': 'stroke-color: ${statesColorMap["failed"]}; stroke-width: 1; fill-color: ${statesColorMap["failed"]}'
};

var xAxisWindow = 60;
var refreshPeriod = 2000;
var animationDuration = 500;

typedef Future<Map<String, int>> GetNewDataForStackedBarChart();

drawMonitorAsStackedBarChart(DivElement monitorContainer, List<String> types,
      GetNewDataForStackedBarChart getNewDataFn) {
  // Make sure that [types] are the types that we support.
  types.forEach((String type) {
    if (statesColorMap.containsKey(type) == false) {
      throw new ArgumentError('Unexpected type: $type.');
    }
  });
  visualization.DataTable data = new visualization.DataTable();
  data.addColumn(new visualization.ColumnDescription(type: 'string', label: 'timestamp', role: 'domain'));
  types.forEach((String type) {
    data
      ..addColumn(new visualization.ColumnDescription(type: 'number', label: type, role: 'data'))
      ..addColumn(new visualization.ColumnDescription(type: 'string', label: '$type-style', role: 'style'));
  });

  // Add just zeros to start with. This makes the actual new data looks like
  // it's appearing from the right, which is nice :)
  var timestamp = 0;
  for (timestamp = 0; timestamp < xAxisWindow; timestamp++) {
    data.addRow(generateEmptyRow(timestamp, types));
  }

  var animationForAddRow = new visualization.AnimationOptions(
      duration: animationDuration,
      easing: 'linear'
    );
  // No animation for now, as it actually takes a lot of CPU...
  animationForAddRow = null;

  var options = new visualization.DrawOptions(
    chartArea: new visualization.ChartAreaOptions(width: '85%'),
    isStacked: true,
    legend: 'none',
    animation: null,
    hAxis: new visualization.HAxisOptions(
      minValue: 0,
      viewWindow: new visualization.ViewWindowOptions(min: 0, max: xAxisWindow),
      textPosition: 'none'
    ),
    bar: new visualization.BarOptions(groupWidth: "98%"),
    vAxis: new visualization.VAxisOptions(
      // If set, moves the max/min value of the vertical axis to the specified
      // value. Ignored if this is set to a value smaller than the
      // maximum/minimum y-value of the data.
      // If unset, automatically scales the y-axis to the data.
      // maxValue: 1000,
      minValue: 10
    ),
    orientation: 'horizontal'
  );

  // Create and draw the chart.
  var chart = new visualization.BarChart(monitorContainer);
  chart.draw(data, options);

  // Run the chart update function every [refreshPeriod].
  updateChart(Timer t) {
    // If we're in the second screen (we have xAxisWindow elements to the left
    // which are not visible anymore), then we clear them up.
    if (options.hAxis.viewWindow.min == 2 * xAxisWindow) {
      data.removeRows(0, xAxisWindow);
      options.hAxis.viewWindow.min -= xAxisWindow;
      options.hAxis.viewWindow.max -= xAxisWindow;
      chart.draw(data, options..animation = null);
    }
    getNewDataFn().then((newData) {
      data.addRow(createRowFromData(timestamp, newData));
      chart.draw(data, options..animation = null);
      options.hAxis.viewWindow.min += 1;
      options.hAxis.viewWindow.max += 1;
      chart.draw(data, options..animation = animationForAddRow);

      timestamp++;
    });
  }
  new Timer.periodic(new Duration(milliseconds: refreshPeriod), updateChart);
}

List createRowFromData(int timestamp, Map<String, int> data) {
  var result = [timestamp.toString()];
  data.forEach((String key, num value) {
    result.add(value.toInt());
    result.add(statesStyleMap[key]);
  });
  return result;
}

List generateEmptyRow(int timestamp, List<String> types) {
  var result = [timestamp.toString()];
  types.forEach((String key) {
    result.add(0);
    result.add(statesStyleMap[key]);
  });
  return result;
}
