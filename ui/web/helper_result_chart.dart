// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sintr_ui;

// Variables that control the visualisation.
const presenceColorMap = const {
  'true': '#3C94F2', // blue
  'false': '#962D2D', // red
};

Map presenceStyleMap = {
  'true':  'stroke-color: ${presenceColorMap["true"]}; stroke-width: 1; fill-color: ${presenceColorMap["true"]}',
  'false':  'stroke-color: ${presenceColorMap["false"]}; stroke-width: 1; fill-color: ${presenceColorMap["false"]}',
};

var xAxisWindowResults = 10;

visualization.DataTable areaData;
visualization.DataTable pieData;
visualization.AreaChart areaChart;
visualization.PieChart pieChart;
visualization.DrawOptions areaOptions;
visualization.DrawOptions pieOptions;

drawResultsChartAsAreaChart(DivElement resultsChartContainer) {
  areaData = new visualization.DataTable();
  areaData
    ..addColumn(new visualization.ColumnDescription(type: 'string', label: 'timestamp', role: 'domain'))
    ..addColumn(new visualization.ColumnDescription(type: 'number', label: 'presence', role: 'data'))
    ..addColumn(new visualization.ColumnDescription(type: 'string', label: 'true-style', role: 'style'))
    ..addColumn(new visualization.ColumnDescription(type: 'number', label: 'presence', role: 'data'))
    ..addColumn(new visualization.ColumnDescription(type: 'string', label: 'false-style', role: 'style'));

  // Add just zeros to start with. This makes the actual new data looks like
  // it's appearing from the right, which is nice :)
  var index = 0;
  for (index = 0; index < xAxisWindowResults; index++) {
    areaData.addRow(generateEmptyRowResults(index));
  }

  areaOptions = new visualization.DrawOptions(
    chartArea: new visualization.ChartAreaOptions(width: '80%'),
    legend: 'none',
    hAxis: new visualization.HAxisOptions(
      minValue: 0
      // viewWindow: new visualization.ViewWindowOptions(min: 0, max: xAxisWindowResults),
      // textPosition: 'none'
    ),
    vAxis: new visualization.VAxisOptions(
      // If set, moves the max/min value of the vertical axis to the specified
      // value. Ignored if this is set to a value smaller than the
      // maximum/minimum y-value of the data.
      // If unset, automatically scales the y-axis to the data.
      maxValue: 1,
      minValue: 0
    ),
    orientation: 'horizontal'
  );

  // Create and draw the chart.
  areaChart = new visualization.AreaChart(resultsChartContainer);
  areaChart.draw(areaData, areaOptions);
}

addDataToResultsChart(Map newData) {
  newData.forEach((String timestamp, bool hogPresence) {
    areaData.addRow([timestamp,
      hogPresence ? 1 : 0, presenceStyleMap['true'],
      hogPresence ? 0 : 1, presenceStyleMap['false']]);
  });
  areaChart.draw(areaData, areaOptions);
}

drawResultsChartAsPieChart(DivElement resultsChartContainer) {
  pieData = new visualization.DataTable();
  pieData
    ..addColumn(new visualization.ColumnDescription(type: 'string', label: 'timestamp', role: 'domain'))
    ..addColumn(new visualization.ColumnDescription(type: 'number', label: 'type', role: 'data'))
    ..addColumn(new visualization.ColumnDescription(type: 'string', label: 'type-style', role: 'style'));
  pieData.addRow(generateEmptyRowPie('true'));
  pieData.addRow(generateEmptyRowPie('false'));

  pieOptions = new visualization.DrawOptions();

  // Create and draw the chart.
  pieChart = new visualization.PieChart(resultsChartContainer);
  pieChart.draw(pieData, pieOptions);
}

addDataToResultsPieChart(Map newData) {
  pieData.setCell(0, 1, newData['true']);
  pieData.setCell(1, 1, newData['false']);
  pieChart.draw(pieData, pieOptions);
}

generateEmptyRowResults(int timestamp) {
  return [timestamp.toString(),
    0, presenceStyleMap['true'],
    0, presenceStyleMap['false'],];
}

generateEmptyRowPie(String type) {
  return [type == 'true' ? 'presence' : 'absence', 0, presenceStyleMap[type]];
}
