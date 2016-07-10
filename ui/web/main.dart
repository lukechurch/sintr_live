// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sintr_ui;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:mdl/mdl.dart';
import 'package:uuid/uuid.dart';

import 'package:sintr_ui/charts/google.charts.dart' as charts;
import 'package:sintr_ui/charts/google.visualization.dart' as visualization;
import 'package:sintr_ui/editing/editor.dart';
import 'package:sintr_ui/editing/editor_codemirror.dart';
import 'package:sintr_ui/editing/keys.dart';

part 'helper_layout.dart';
part 'helper_monitor.dart';
part 'helper_result_chart.dart';
part 'helper_server_poller.dart';
part 'utils.dart';


DivElement rawInput;
DivElement rawOutput;
DivElement outputHistogram;
DivElement errorsOutput;
DivElement nodesStatus;
DivElement tasksStatus;

Map<DivElement, Neighbours> connections = {};

/// List representing the order in which things appear on screen. The last in
/// list is the topmost one on screen.
List<DivElement> zOrderedElements;

// Code mirror things
// final String dartServicesURL = 'https://dart-services.appspot.com/';
final String dartServicesURL = 'http://127.0.0.1:11001';
final String setNodeCountPath = 'setNodeCount';
final String codeKey = new Uuid().v1().toString();

Keys keys = new Keys();
EditorFactory get editorFactory => codeMirrorFactory;

final MaterialSnackbar snackbar = new MaterialSnackbar();

Map<DivElement, Editor> editors = {};
Map resultsData = {};
Map resultsErrors = {};

// A boolean set in the UI that marks whether the run command is sent only
// when clicking the Run button or automatically, after every keystroke.
bool autoRun;

void runCode() {
  // Clear previous data
  resultsData = {};
  resultsErrors = {};

  // Make the request to run the code.
  var url = '$dartServicesURL/runCode';
  Map<String, String> sources = {};
  editors.forEach((DivElement codePanel, Editor editor) {
    String title = codePanel.querySelector('.panel-title').text;
    String filename = title.endsWith('.dart') ? title : '$title.dart';
    String code = editor.document.value;
    sources[filename] = code;
  });
  Map<String, dynamic> message = {
    "sources": sources,
  };
  new HttpRequest()
    ..open("POST", url)
    ..onLoad.listen((event) {
      // Poll for new results.
      var poller = new Poller(
        "$dartServicesURL/isDone",
        "$dartServicesURL/results",
        updateResults);
      poller.startPolling();
    })
    ..send(JSON.encode(message));

  // Create a new chart for the results.
  drawResultsChartAsAreaChart(outputHistogram.querySelector('.areaChart'));
  drawResultsChartAsPieChart(outputHistogram.querySelector('.pieChart'));
}

void updateResults(String results) {
  Map resultsMap = JSON.decode(results);
  Map newData = resultsMap['data'];
  Map newErrors = resultsMap['errors'];

  resultsData.addAll(newData);
  newErrors.forEach((key, value) {
    if (resultsErrors.containsKey(key)) {
      resultsErrors[key] = resultsErrors[key] + value;
    } else {
      resultsErrors[key] = value;
    }
  });

  rawOutput.querySelector('.card-contents').innerHtml =
      outputMapStringify(resultsData);
  errorsOutput.querySelector('.card-contents').innerHtml =
      errorMapStringify(resultsErrors);

  // Extract new statistics about the results and add them to the chart.
  int trueCount = resultsData.values.where((bool value) => value == true).length;
  int falseCount = resultsData.values.where((bool value) => value == false).length;

  addDataToResultsChart(newData);
  addDataToResultsPieChart({'true': trueCount, 'false': falseCount});
}

// TODO(mariana): consider removing all other code files from the UI (if any present) when this is called.
void getDefaultSourceCode() {
  // Make the request to get the default source code.
  var url = '$dartServicesURL/sources';
  HttpRequest.getString(url).then((String sourcesJson) {
    Map<String, String> sources = JSON.decode(sourcesJson);
    sources.forEach((String filename, String code) => addNewCodeEditor(filename: filename, code: code));
    dockAndFoldAllCodeEditors();
  });
}

void getSampleInput() {
  // Make the request to get the sample input.
  var url = '$dartServicesURL/sampleInput';
  HttpRequest.getString(url).then((String sampleInput) {
    rawInput.querySelector('.card-contents').innerHtml =
        inputMapStringify(JSON.decode(sampleInput));
  });
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

void main() {
  // Load Material Design Lite.
  // Even though we're not using anything but the CSS, we still need to do this for the animations & the changes in the buttons.
  registerMdl();
  componentFactory().run().then((_) {
    snackbar.position
      ..bottom = true
      ..top = false
      ..right = true
      ..left = false;
  });

  captureSaveCommand();

  // Load Google Charts.
  charts.load('current', new charts.GoogleChartsLoadOptions(packages: ['corechart', 'bar']));

  // Initialize the elements of the UI.
  rawInput = querySelector('#raw-input');
  rawOutput = querySelector('#raw-output');
  outputHistogram = querySelector('#output-histogram');
  errorsOutput = querySelector('#errors-output');
  nodesStatus = querySelector('#nodes-status');
  tasksStatus = querySelector('#tasks-status');

  // Initialize the neighbours of the elements of the UI.
  connections[rawInput] = new Neighbours();
  connections[rawOutput] = new Neighbours();
  connections[outputHistogram] = new Neighbours();
  connections[errorsOutput] = new Neighbours();
  connections[nodesStatus] = new Neighbours();
  connections[tasksStatus] = new Neighbours();

  // Attach listeners for the title bar buttons.
  attachTitleBarButtonsListeners(rawInput);
  attachTitleBarButtonsListeners(rawOutput);
  attachTitleBarButtonsListeners(outputHistogram);
  attachTitleBarButtonsListeners(errorsOutput);
  attachTitleBarButtonsListeners(nodesStatus);
  attachTitleBarButtonsListeners(tasksStatus);

  // Set the order in which things are displayed on the screen.
  // This matches initially with the order in the DOM.
  zOrderedElements = [rawInput, rawOutput, outputHistogram, errorsOutput, nodesStatus, tasksStatus];

  // Attach listeners for movement and resizing.
  attachMovementListener(rawInput, zOrderedElements);
  attachMovementListener(rawOutput, zOrderedElements);
  attachMovementListener(outputHistogram, zOrderedElements);
  attachMovementListener(errorsOutput, zOrderedElements);
  attachMovementListener(nodesStatus, zOrderedElements);
  attachMovementListener(tasksStatus, zOrderedElements);

  // Set the callback for drawing the node monitor chart.
  var nodesUrl = '$dartServicesURL/nodesStatus';
  // charts.setOnLoadCallback(allowInterop(() =>
  //     drawMonitorAsStackedBarChart(nodesStatus.querySelector('.contents'), ['ready', 'active'], () {
  //       return HttpRequest.getString(nodesUrl).then((String nodesStatusData) {
  //         return JSON.decode(nodesStatusData);
  //       });
  //     })));

  // Set the callback for drawing the task monitor chart.
  var tasksUrl = '$dartServicesURL/tasksStatus';
  // charts.setOnLoadCallback(allowInterop(() =>
  //     drawMonitorAsStackedBarChart(tasksStatus.querySelector('.contents'), ['ready', 'active', 'done', 'failed'], () {
  //       return HttpRequest.getString(tasksUrl).then((String tasksStatusData) {
  //         return JSON.decode(tasksStatusData);
  //       });
  //     })));

  // Add callback to the Run button.
  // TODO(mariana): Add a class to the button to identify it, as there may be other buttons in the code editor.
  querySelector('#run-button').onClick.listen((_) => runCode());
  InputElement autoRunCheckbox = querySelector('#auto-run-checkbox').querySelector('input');
  autoRunCheckbox.onChange.listen((e) {
    autoRun = autoRunCheckbox.checked;
  });

  // Add listener to the FAB for adding new code windows
  querySelector('#add-nodule').onClick.listen((_) => addNewCodeEditor());

  // Add listener for the node count update
  querySelector('#set-node-count-button').onClick.listen((_) {
    String textfieldValue = "";
    try {
      textfieldValue = (querySelector('#node-count-textfield') as InputElement).value;
      int nodeCount = int.parse(textfieldValue);
      new HttpRequest()
        ..open("POST", "$dartServicesURL/$setNodeCountPath")
        ..onLoad.listen((event) {
          print(event.target.responseText);
          snackbar(event.target.responseText).show();
        })
        ..send(JSON.encode({'count': nodeCount}));
    } catch (e) {
      window.alert('Number of nodes must be a positive number, but you have entered \"$textfieldValue\".\n');
    }
  });

  // Get the starting code files from the server and display them in the UI.
  getDefaultSourceCode();

  // Get the sample input from the server and display it in the UI.
  getSampleInput();
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

attachTitleBarButtonsListeners(DivElement e) {
  ButtonElement closeButton = e.querySelector('.icon--close');
  if (closeButton != null) {
    closeButton.onClick.listen((MouseEvent event) {
      removeParentConnections(e);
      removeChildrenConnections(e);
      connections.remove(e);
      e.remove();
      editors.remove(e);
    });
  }

  ButtonElement foldButton = e.querySelector('.icon--fold-unfold');
  if (foldButton != null) {
    foldButton.onClick.listen((MouseEvent event) {
      if (foldButton.innerHtml.contains('unfold_less')) {
        // First save the previous height & mark the height as unchangeable
        // (until the unfold button is pressed again).
        e.attributes['original_height'] = e.style.height;
        e.attributes['fixed-height'] = "";
        // Set the transition
        // e.style.transition = 'height 5s';
        // e.onTransitionEnd.first.then((_) => e.style.transition = '');
        e.style.height = '16px';
        // Propagate the change to the children neighbours.
        int heightDiff = 16 - pxValueToInt(e.attributes['original_height']);
        propagateFoldToChildren(e, heightDiff);
        // Replace the button
        foldButton.querySelector('i').text = 'unfold_more';
        componentHandler().upgradeElement(foldButton);
      } else if (foldButton.innerHtml.contains('unfold_more')) {
        // Set the transition
        // e.style.transition = 'height 5s';
        // e.onTransitionEnd.first.then((_) => e.style.transition = '');
        e.style.height = e.attributes['original_height'];
        // Propagate the change to the children neighbours.
        int heightDiff = pxValueToInt(e.attributes['original_height']) - 16;
        propagateFoldToChildren(e, heightDiff);
        // Remove the height limitations
        e.attributes.remove('original_height');
        e.attributes.remove('fixed-height');
        //Replace the button
        foldButton.querySelector('i').text = 'unfold_less';
        componentHandler().upgradeElement(foldButton);
      }
    });
  }

  HeadingElement title = e.querySelector('.panel-title');
  if (title != null) {
    title.onDoubleClick.listen((Event event) {
      title.contentEditable = 'true';
      title.focus();

      // Clicking outside the title marks it as not editable again.
      StreamSubscription<MouseEvent> documentOnClickSubscription;
      documentOnClickSubscription = document.onClick.listen((Event event) {
        if (event.target != title) {
          title.contentEditable = 'false';
          documentOnClickSubscription.cancel();
        }
      });

      // Pressing Enter marks it as not editable again.
      StreamSubscription<KeyboardEvent> keyDownSubscription;
      keyDownSubscription = title.onKeyDown.listen((KeyboardEvent event) {
        if (event.keyCode == 13) {
          event.preventDefault();
          title.contentEditable = 'false';
          keyDownSubscription.cancel();
        }
      });
    });
  }
}

initKeyBindings() {
  // No actions yet for Save and Run.
  keys.bind(['ctrl-s'], () {}, "Save", hidden: true);
  keys.bind(['ctrl-enter'], () {}, "Run");

  // No actions yet for Quick fixes and Completions.
  keys.bind(['alt-enter', 'ctrl-1'], () {}, "Quick fix");
  keys.bind(['ctrl-space', 'macctrl-space'], () {}, "Completion");
}
