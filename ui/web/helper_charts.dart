// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sintr_ui;

/// The data to be visualised. It's updated everytime new data comes from the server.
Map<String, List<Map>> _data = {'Series1': []};
plotly.Plot plot;

var plotLayout = {
  'autosize': true,
  'margin': {
    't': 20,
    'l': 40,
    'r': 40,
    'b': 60,
  }
};

SelectElement typeMenu;
SelectElement xAxisMenu;
SelectElement yAxisMenu;
SelectElement sortAxisMenu;
DivElement chart;

/// The parent must contain 4 select elements with the classes "type-menu",
/// "x-axis-menu", "y-axis-menu", "sortAxisMenu", and a div element
/// with the class "chart-container".
initializeChartControls(Element parent) {
  typeMenu = parent.querySelector('.type-menu');
  xAxisMenu = parent.querySelector('.x-axis-menu');
  yAxisMenu = parent.querySelector('.y-axis-menu');
  sortAxisMenu = parent.querySelector('.sort-axis-menu');
  chart = parent.querySelector('.chart-container');

  typeMenu.onChange.listen((Event event) => generateChart(chart, typeMenu, xAxisMenu, yAxisMenu, sortAxisMenu, _data));

  Function disableOtherAxisOption = (SelectElement thisAxis, SelectElement otherAxis) {
    otherAxis.options.forEach((OptionElement option) {
      // Enable all other options.
      if (option.disabled) {
        option.disabled = false;
      }
      // Disable selected option.
      if (option.value == thisAxis.value) {
        option.disabled = true;
      }
    });
  };
  xAxisMenu.onChange.listen((Event event) {
    generateChart(chart, typeMenu, xAxisMenu, yAxisMenu, sortAxisMenu, _data);
    disableOtherAxisOption(xAxisMenu, yAxisMenu);
  });
  yAxisMenu.onChange.listen((Event event) {
    generateChart(chart, typeMenu, xAxisMenu, yAxisMenu, sortAxisMenu, _data);
    disableOtherAxisOption(yAxisMenu, xAxisMenu);
  });
  sortAxisMenu.onChange.listen((Event event) {
    generateChart(chart, typeMenu, xAxisMenu, yAxisMenu, sortAxisMenu, _data);
  });
}

updateChartWithData(dataToBePlotted) {
  chart..nodes.clear(); // Remove old chart

  // Force the data into a Map<String, List> format.
  if (dataToBePlotted is List) {
    _data = {'Series1': dataToBePlotted};
  } else {
    _data = dataToBePlotted;
  }

  Set<String> previousAxisLabels = xAxisMenu.options.map((OptionElement e) => e.value).toSet();
  Set<String> axisLabels = new Set();
  _data.values.first.forEach(
      (Map<String, dynamic> dataPoint) => axisLabels.addAll(dataPoint.keys));
  Set<String> symmetricDifference = previousAxisLabels.difference(axisLabels)
      .union(axisLabels.difference(previousAxisLabels));
  if (symmetricDifference.isEmpty) {
    // The labels haven't changed since last run.
  } else {
    // The labels have changed. Reset everything.
    xAxisMenu.nodes.clear();
    yAxisMenu.nodes.clear();
    axisLabels.forEach(
      (String label) => xAxisMenu.append(new OptionElement(data: label, value: label)));
    axisLabels.forEach(
      (String label) => yAxisMenu.append(new OptionElement(data: label, value: label)));
    xAxisMenu.selectedIndex = 0; // First value, whatever it is.
    yAxisMenu.selectedIndex = 1; // Second value, whatever it is. TODO(mariana): make sure that there are more than 2 values.
    (xAxisMenu.item(1) as OptionElement).disabled = true;
    (yAxisMenu.item(0) as OptionElement).disabled = true;
  }

  plot = generateChart(chart, typeMenu, xAxisMenu, yAxisMenu, sortAxisMenu, _data);
}

plotly.Plot generateChart(DivElement chart, SelectElement typeMenu, SelectElement xAxisMenu, SelectElement yAxisMenu, SelectElement sortAxisMenu, Map<String, List<Map>> data) {
  plotly.Plot plot;
  if (typeMenu.selectedIndex == 0) { // Scatter plot
    List dataList = [];
    data.forEach((String series, List dataPoints) {
      List dataPointsSorted = sortListBasedOnSortMenu(dataPoints, xAxisMenu.value, yAxisMenu.value, sortAxisMenu);
      dataList.add({
        'x': dataPointsSorted.map((Map dataPoint) => dataPoint[xAxisMenu.value]).toList(),
        'y': dataPointsSorted.map((Map dataPoint) => dataPoint[yAxisMenu.value]).toList(),
        'mode': 'markers',
      });
    });
    plot = new plotly.Plot(chart, dataList, plotLayout, staticPlot: true);
  } else { // Bar chart
    List dataList = [];
    data.forEach((String series, List dataPoints) {
      List dataPointsSorted = sortListBasedOnSortMenu(dataPoints, xAxisMenu.value, yAxisMenu.value, sortAxisMenu);
      dataList.add({
        'x': dataPointsSorted.map((Map dataPoint) => dataPoint[xAxisMenu.value]).toList(),
        'y': dataPointsSorted.map((Map dataPoint) => dataPoint[yAxisMenu.value]).toList(),
        'type': 'bar',
      });
    });
    plot = new plotly.Plot(chart, dataList, plotLayout, staticPlot: true);
  }
  plot.relayout(plotLayout);
  return plot;
}

List sortListBasedOnSortMenu(List<Map> data, String xAxisField, String yAxisField, SelectElement sortAxisMenu) {
  List dataPoints = new List.from(data);
  switch (sortAxisMenu.value) {
    case 'unsort':
      break;
    case 'x-asc':
      dataPoints.sort((Map dataPoint, Map otherDataPoint) {
        if (dataPoint[xAxisField] is num && otherDataPoint[xAxisField] is num) {
          return dataPoint[xAxisField] - otherDataPoint[xAxisField];
        } else {
          return dataPoint[xAxisField].toString().compareTo(otherDataPoint[xAxisField].toString());
        }
      });
      break;
    case 'x-desc':
      dataPoints.sort((Map dataPoint, Map otherDataPoint) {
        if (dataPoint[xAxisField] is num && otherDataPoint[xAxisField] is num) {
          return otherDataPoint[xAxisField] - dataPoint[xAxisField];
        } else {
          return otherDataPoint[xAxisField].toString().compareTo(dataPoint[xAxisField].toString());
        }
      });
      break;
    case 'y-asc':
      dataPoints.sort((Map dataPoint, Map otherDataPoint) {
        if (dataPoint[yAxisField] is num && otherDataPoint[yAxisField] is num) {
          return dataPoint[yAxisField] - otherDataPoint[yAxisField];
        } else {
          return dataPoint[yAxisField].toString().compareTo(otherDataPoint[yAxisField].toString());
        }
      });
      break;
    case 'y-desc':
      dataPoints.sort((Map dataPoint, Map otherDataPoint) {
        if (dataPoint[yAxisField] is num && otherDataPoint[yAxisField] is num) {
          return otherDataPoint[yAxisField] - dataPoint[yAxisField];
        } else {
          return otherDataPoint[yAxisField].toString().compareTo(dataPoint[yAxisField].toString());
        }
      });
      break;
  }
  return dataPoints;
}
