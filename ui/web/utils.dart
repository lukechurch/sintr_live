// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sintr_ui;

class Neighbours {
  DivElement top;
  DivElement bottom;
  // DivElement left;
  // DivElement right;

  // If [e] is part of this collection of neighbors, then it's removed.
  void removeDiv(DivElement e) {
    top = (top == e) ? null : e;
    bottom = (bottom == e) ? null : e;
  }
}

void captureSaveCommand() {
  document.onKeyDown.listen((KeyboardEvent event) {
    if (event.ctrlKey || event.metaKey) {
      switch (new String.fromCharCode(event.which).toLowerCase()) {
        case 's':
          event.preventDefault();
          break;
      }
    }
  });
}

var sanitizer = const HtmlEscape();
String indent = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';

String outputMapStringify(outputMap) {
  StringBuffer result = new StringBuffer();
  outputMap.forEach((String key, bool value) {
    result.writeln('$key: $value<br>');
  });
  return result.toString();
}

String errorMapStringify(Map<String, int> errorMap) {
  List<String> sortedErrors = errorMap.keys.toList();
  // Sort the errors so that the one with most occurences is first.
  sortedErrors.sort((String e1, String e2) => -errorMap[e1].compareTo(errorMap[e2]));

  StringBuffer result = new StringBuffer();
  sortedErrors.forEach((String error) {
    // Number of occurences appears bold.
    result.writeln('<b>${errorMap[error]} occurences. Error:</b><br>');
    // The first line of the error appears bold and indented.
    result.writeln(indent + '<b>' + sanitizer.convert(error.split('\n').first) + '</b><br>');
    // The next lines of the error appear indented.
    error.split('\n')..sublist(1).forEach((String line) {
      result.writeln(indent + sanitizer.convert(line) + '<br>');
    });
    result.writeln('<br>');
  });
  return result.toString();
}

String inputMapStringify(Map<String, String> inputMap) {
  StringBuffer result = new StringBuffer();
  inputMap.forEach((String file, String contents) {
    // File name appears bold.
    result.writeln('<b>$file:</b><br>');
    // The lines from the file appear indented.
    contents.split('\n').forEach((String line) {
      result.writeln(indent + sanitizer.convert(line) + '<br>');
    });
    result.writeln('<br>');
  });
  return result.toString();
}

bool containsClassOnParentPath(Element target, String className) {
  Element pathIterator = target;
  while (pathIterator != querySelector('body')) {
    if (pathIterator == null) {
      return false;
    }
    if (pathIterator.classes.contains(className)) {
      return true;
    }
    pathIterator = pathIterator.parent;
  }
  return false;
}

DivElement newCodePanel(String title) {
  DivElement panel = newEmptyPanel(style: {'width': '604px', 'height': '400px', 'left': 'calc((100% - 604px)/2)', 'top': 'calc((100% - 400px)/2)'}, withResizeControls: true);
  panel
      ..classes.add('code-panel')
      ..style.display = 'flex'
      ..style.flexFlow = 'column';
  panel.appendHtml(
    """<div class="title-bar-buttons">
        <button class="mdl-button mdl-js-button mdl-button--icon icon--fold-unfold"><i class="material-icons">unfold_less</i></button>
        <button class="mdl-button mdl-js-button mdl-button--icon icon--close"><i class="material-icons">close</i></button>
       </div>""");
  componentHandler().upgradeElement(panel);
  panel.append(new HeadingElement.h1()
      ..classes.add('panel-title')
      ..style.flex = '0 1 auto'
      ..text = title);
  panel.append(new DivElement()
      ..classes.add('code')
      ..style.flex = '1 1 auto');
  return panel;
}

int pxValueToInt(String pxValue) {
  return int.parse(pxValue.replaceFirst('px', ''));
}

DivElement newEmptyPanel({String id, Map<String, String> style, bool withResizeControls: false}) {
  String idAttribute = id != null && id.length > 0 ? "id=\"$id\"" : "";
  StringBuffer styleAttributeBuffer = new StringBuffer("style=\"");
  style.forEach((String param, String value) => styleAttributeBuffer.write('$param: $value;'));
  styleAttributeBuffer.write('\"');
  String resizeControls = withResizeControls ?
      """<div class="resize-controls">
          <div class="top-left"></div><div class="top-right"></div><div class="bottom-left"></div><div class="bottom-right"></div>
          <div class="top"></div><div class="right"></div><div class="left"></div><div class="bottom"></div>
         </div>""" : "";
  return new Element.html("""<div $idAttribute ${styleAttributeBuffer.toString()} class="panel mdl-panel mdl-panel--shadow"> $resizeControls </div>""",
      validator: new NodeValidatorBuilder()
          ..allowHtml5()
          ..allowInlineStyles());
}

int maxDistanceInPx = 20;
prepareSnapToOtherPanels(DivElement panel) {
  for (DivElement other in connections.keys) {
    other.style.border = '';
    panel.style.border = '';
    String borderStyle = '2px solid #ff5252';
    // Only try to snap to panels which intersect this panel vertically
    if ((other.borderEdge.left < panel.borderEdge.left && other.borderEdge.right < panel.borderEdge.left) ||
        (other.borderEdge.left > panel.borderEdge.right && other.borderEdge.right > panel.borderEdge.right)) {
      continue;
    }
    // Only try to snap borders which are not connected yet.
    if (!panel.classes.contains('connected-border--bottom') &&
        !other.classes.contains('connected-border--top') &&
        (other.borderEdge.top - panel.borderEdge.bottom).abs() < maxDistanceInPx) {
      other.style.borderTop = borderStyle;
      panel.style.borderBottom = borderStyle;
      break;
    } else if (!panel.classes.contains('connected-border--top') &&
        !other.classes.contains('connected-border--bottom') &&
        (other.borderEdge.bottom - panel.borderEdge.top).abs() < maxDistanceInPx) {
      other.style.borderBottom = borderStyle;
      panel.style.borderTop = borderStyle;
      break;
    }
  }
}

handleSnapToOtherPanels(DivElement panel, {bool useHeightInsteadOfTop: false}) {
  Neighbours panelNeighbours = connections[panel];
  for (DivElement other in connections.keys) {
    other.style.border = '';
    panel.style.border = '';
    Neighbours otherNeighbours = connections[other];
    // Only try to snap to panels which intersect this panel vertically
    if ((other.borderEdge.left < panel.borderEdge.left && other.borderEdge.right < panel.borderEdge.left) ||
        (other.borderEdge.left > panel.borderEdge.right && other.borderEdge.right > panel.borderEdge.right)) {
      continue;
    }
    // Only try to snap borders which are not connected yet.
    if (!panel.classes.contains('connected-border--bottom') &&
        !other.classes.contains('connected-border--top') &&
        (other.borderEdge.top - panel.borderEdge.bottom).abs() < maxDistanceInPx) {
      other.classes.add('connected-border--top');
      panel.classes.add('connected-border--bottom');
      if (useHeightInsteadOfTop) {
        int newHeight = panel.contentEdge.height + // the previous height plus the change, which is
            // the difference between the new border edge and the previous one.
            (other.offset.top - panel.offset.top) - panel.borderEdge.height;
        panel.style.height = '${newHeight}px';
      } else {
        int newTopOffset = other.offset.top - panel.borderEdge.height;
        moveChildrenConnections(panel, 0, newTopOffset - panel.offset.top);
        panel.style.top = '${newTopOffset}px';
      }
      // Set the relationship here and not above because otherwise it interferes
      // with moveChildrenConnections.
      otherNeighbours.top = panel;
      panelNeighbours.bottom = other;
      break;
    } else if (!panel.classes.contains('connected-border--top') &&
        !other.classes.contains('connected-border--bottom') &&
        (other.borderEdge.bottom - panel.borderEdge.top).abs() < maxDistanceInPx) {
      other.classes.add('connected-border--bottom');
      panel.classes.add('connected-border--top');
      otherNeighbours.bottom = panel;
      panelNeighbours.top = other;
      int newTopOffset = other.offset.top + other.borderEdge.height;
      moveChildrenConnections(panel, 0, newTopOffset - panel.offset.top);
      panel.style.top = '${newTopOffset}px';
    }
  }
}

removeParentConnections(DivElement panel) {
  Neighbours panelNeighbours = connections[panel];
  if (panelNeighbours == null || panelNeighbours.top == null) {
    return;
  }
  Neighbours topNeighbours = connections[panelNeighbours.top];
  topNeighbours.bottom = null;
  panelNeighbours.top.classes.remove('connected-border--bottom');
  panelNeighbours.top = null;
  panel.classes.remove('connected-border--top');
}

removeChildrenConnections(DivElement panel) {
  Neighbours panelNeighbours = connections[panel];
  if (panelNeighbours == null || panelNeighbours.bottom == null) {
    return;
  }
  Neighbours bottomNeighbours = connections[panelNeighbours.bottom];
  bottomNeighbours.top = null;
  panelNeighbours.bottom.classes.remove('connected-border--top');
  panelNeighbours.bottom = null;
  panel.classes.remove('connected-border--bottom');
}

moveChildrenConnections(DivElement panel, int movementX, int movementY) {
  Neighbours panelNeighbours = connections[panel];
  if (panelNeighbours == null || panelNeighbours.bottom == null) {
    return;
  }
  DivElement bottomPanel = panelNeighbours.bottom;
  bottomPanel.style.left = '${bottomPanel.offset.left + movementX}px';
  bottomPanel.style.top = '${bottomPanel.offset.top + movementY}px';
  moveChildrenConnections(bottomPanel, movementX, movementY);
}

propagateFoldToChildren(DivElement panel, int heightDiff) {
  Neighbours panelNeighbours = connections[panel];
  if (panelNeighbours == null || panelNeighbours.bottom == null) {
    return;
  }
  DivElement bottomPanel = panelNeighbours.bottom;
  // bottomPanel.style.transition = 'top 5s';
  // bottomPanel.onTransitionEnd.listen((_) => bottomPanel.style.transition = '');
  bottomPanel.style.top = '${bottomPanel.offset.top + heightDiff}px';
  propagateFoldToChildren(bottomPanel, heightDiff);
}

plotly.Plot plot;
var plotLayout = {
  'autosize': true,
  'margin': {
    't': 20,
    'l': 40,
    'r': 40,
    'b': 40,
  }
};

/// The parent must contain 3 select elements with the classes "type-menu",
/// "x-axis-menu", "y-axis-menu", and a div element with the class "chart-container".
showResultsInChart(Element parent, data) {
  SelectElement typeMenu = parent.querySelector('.type-menu');
  SelectElement xAxisMenu = parent.querySelector('.x-axis-menu')..nodes.clear();
  SelectElement yAxisMenu = parent.querySelector('.y-axis-menu')..nodes.clear();
  SelectElement sortAxisMenu = parent.querySelector('.sort-axis-menu');
  DivElement chart = parent.querySelector('.chart-container')..nodes.clear();

  if (data is List) {
    data = {'Series1': data};
  }
  Set<String> axisLabels = new Set();
  data.values.first.forEach(
    (Map<String, dynamic> dataPoint) => axisLabels.addAll(dataPoint.keys));
  axisLabels.forEach(
    (String label) => xAxisMenu.append(new OptionElement(data: label, value: label)));
  axisLabels.forEach(
    (String label) => yAxisMenu.append(new OptionElement(data: label, value: label)));

  typeMenu.selectedIndex = 0; // Scatter plot
  xAxisMenu.selectedIndex = 0; // First value, whatever it is.
  yAxisMenu.selectedIndex = 1; // Second value, whatever it is. TODO(mariana): make sure that there are more than 2 values.
  (xAxisMenu.item(1) as OptionElement).disabled = true;
  (yAxisMenu.item(0) as OptionElement).disabled = true;

  typeMenu.onChange.listen((Event event) => generateChart(chart, typeMenu, xAxisMenu, yAxisMenu, sortAxisMenu, data));

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
    generateChart(chart, typeMenu, xAxisMenu, yAxisMenu, sortAxisMenu, data);
    disableOtherAxisOption(xAxisMenu, yAxisMenu);
  });
  yAxisMenu.onChange.listen((Event event) {
    generateChart(chart, typeMenu, xAxisMenu, yAxisMenu, sortAxisMenu, data);
    disableOtherAxisOption(yAxisMenu, xAxisMenu);
  });
  sortAxisMenu.onChange.listen((Event event) {
    generateChart(chart, typeMenu, xAxisMenu, yAxisMenu, sortAxisMenu, data);
  });

  plot = generateChart(chart, typeMenu, xAxisMenu, yAxisMenu, sortAxisMenu, data);
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
        print (dataPoint.toString() + ' - ' + otherDataPoint.toString());
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


void dockAndFoldAllCodeEditors() {
  List<DivElement> panels = editors.keys.toList();
  for (int i = 0; i < panels.length; i++) {
    DivElement panel = panels[i];
    panel
      ..style.top = '${30 + 48*i}px'
      ..style.left = '542px';
    handleSnapToOtherPanels(panel);
    ButtonElement foldButton = panel.querySelector('.icon--fold-unfold');
    foldButton.click();
  }
}


Map<String, String> collectCodeSources() {
  Map<String, String> sources = {};
  editors.forEach((DivElement codePanel, Editor editor) {
    String filename = codePanel.querySelector('.panel-title').text;
    String code = editor.document.value;
    sources[filename] = code;
  });
  return sources;
}

logResponseInOutputPanel(HttpRequest request, String panelId) {
  String responseText = request.responseText;
  if (request.status == 200) {
    String responseText = request.responseText;
    var response;
    // Try to encode with it a JSON pretty printer
    try {
      response = JSON.decode(JSON.decode(responseText)['result']);
      print(JSON.encode(response));
      JsonEncoder encoder = new JsonEncoder.withIndent("  ");
      responseText = encoder.convert(response);
    } catch (e, st) {
      print ("Decoding failed");
      print (e);
      print (st);
      return;
    }
    if (response is List) {
      response = {'dataSeries': response};
    }
    querySelector('#$panelId').querySelector('.card-contents').querySelector('pre').text = responseText;
    showResultsInChart(querySelector('#output-histogram').querySelector('.card-contents'), response);
  } else {
    querySelector('#$panelId').querySelector('.card-contents').querySelector('pre').text = 'Request failed, status=${request.status}\n\n$responseText';
  }
}

addNewCodeEditor({String filename: 'default.dart', String code: ''}) {
  DivElement codePanel = newCodePanel(filename);
  componentHandler().upgradeElement(codePanel); // for the mdl-library
  querySelector('main').append(codePanel);
  connections[codePanel] = new Neighbours();
  zOrderedElements.add(codePanel);
  setOnTop(codePanel, zOrderedElements);
  attachMovementListener(codePanel, zOrderedElements);
  attachTitleBarButtonsListeners(codePanel);
  editors[codePanel] = createNewEditor(codePanel.querySelector('.code'));
  editors[codePanel].document.applyEdit(new SourceEdit(0, 0, code));
}

Editor createNewEditor(DivElement editorContainer) {
  Editor editor = editorFactory.createFromElement(editorContainer);
  // editorContainer.querySelector('.CodeMirror').attributes['flex'] = '';
  editor.resize();
  editor.mode = 'dart';
  editor.document.onChange.listen((bool codeChanged) {
    if (codeChanged && autoRun) {
      runCode();
    }
  });
  return editor;
}
