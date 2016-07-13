// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sintr_ui;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:http/browser_client.dart';
import 'package:http/http.dart';
import 'package:mdl/mdl.dart';
import 'package:plotly/plotly.dart' as plotly;
import 'package:uuid/uuid.dart';

import 'package:sintr_ui/editing/completion.dart';
import 'package:sintr_ui/editing/editor_codemirror.dart';
import 'package:sintr_ui/editing/editor.dart';
import 'package:sintr_ui/editing/keys.dart';
import 'package:sintr_ui/services/dartservices.dart' as dartservices;

part 'helper_charts.dart';
part 'helper_editor.dart';
part 'helper_layout.dart';
part 'helper_server_poller.dart';
part 'panel_definitions.dart';
part 'utils.dart';


DivElement mapperInput;
DivElement mapperOutputReducerInput;
DivElement reducerOutput;
DivElement reducerChart;
DivElement errorsOutput;
DivElement nodesStatus;
DivElement tasksStatus;

Map<DivElement, Neighbours> connections = {};

/// List representing the order in which things appear on screen. The last in
/// list is the topmost one on screen.
List<DivElement> zOrderedElements;

// Code mirror things
final String dartServicesURL = 'https://dart-services.appspot.com/';
final String sintrServerURL = 'http://127.0.0.1:8990';
final Duration serviceCallTimeout = new Duration(seconds: 10);

final String setNodeCountPath = 'setNodeCount';
final String codeKey = new Uuid().v1().toString();

Keys keys = new Keys();
EditorFactory get editorFactory => codeMirrorFactory;
dartservices.DartservicesApi dartServices;

final MaterialSnackbar snackbar = new MaterialSnackbar();

Map<DivElement, Editor> editors = {};
Map resultsData = {};
Map resultsErrors = {};

int pageWidth;
int pageHeight;
int distanceBetweenPanels;
int panelPadding;
int widthUnit;
int heightUnit;

// A boolean set in the UI that marks whether the run command is sent only
// when clicking the Run button or automatically, after every keystroke.
bool autoRun;

void runCode() {
  // TODO(mariana) Should be replaced with calls to local or remote exec.
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

  // Initialize the elements of the UI.
  mapperInput = newInputOutputPanel('Map input', 'map-input');
  mapperInput.querySelector('pre').contentEditable = 'true';
  mapperOutputReducerInput = newInputOutputPanel('Map output / Reducer input', 'map-output-reducer-input');
  reducerOutput = newInputOutputPanel('Reducer output', 'reducer-output');
  reducerChart = newChartPanel('reducer-chart');
  errorsOutput = newInputOutputPanel('Errors', 'errors-output');
  nodesStatus = newInputOutputPanel('Sintr nodes status', 'nodes-status');
  tasksStatus = newInputOutputPanel('Compute tasks status', 'tasks-status');

  layoutPanels(mapperInput, mapperOutputReducerInput, reducerOutput, reducerChart, errorsOutput, nodesStatus, tasksStatus);
  // Add the panels to the DOM
  querySelector('main').append(mapperInput);
  querySelector('main').append(mapperOutputReducerInput);
  querySelector('main').append(reducerOutput);
  querySelector('main').append(reducerChart);
  querySelector('main').append(errorsOutput);
  querySelector('main').append(nodesStatus);
  querySelector('main').append(tasksStatus);

  // Initialize the neighbours of the elements of the UI.
  connections[mapperInput] = new Neighbours();
  connections[mapperOutputReducerInput] = new Neighbours();
  connections[reducerOutput] = new Neighbours();
  connections[reducerChart] = new Neighbours();
  connections[errorsOutput] = new Neighbours();
  connections[nodesStatus] = new Neighbours();
  connections[tasksStatus] = new Neighbours();

  // Snap any panels which can be snapped
  handleSnapToOtherPanels(mapperInput);
  handleSnapToOtherPanels(mapperOutputReducerInput);
  handleSnapToOtherPanels(reducerOutput);
  handleSnapToOtherPanels(nodesStatus);
  handleSnapToOtherPanels(tasksStatus);
  handleSnapToOtherPanels(errorsOutput);
  handleSnapToOtherPanels(reducerChart);

  // Attach listeners for the title bar buttons.
  attachTitleBarButtonsListenersToElement(mapperInput);
  attachTitleBarButtonsListenersToElement(mapperOutputReducerInput);
  attachTitleBarButtonsListenersToElement(reducerOutput);
  attachTitleBarButtonsListenersToElement(reducerChart);
  attachTitleBarButtonsListenersToElement(errorsOutput);
  attachTitleBarButtonsListenersToElement(nodesStatus);
  attachTitleBarButtonsListenersToElement(tasksStatus);

  // Set the order in which things are displayed on the screen.
  // This matches initially with the order in the DOM.
  zOrderedElements = [mapperInput, mapperOutputReducerInput, reducerOutput, reducerChart, errorsOutput, nodesStatus, tasksStatus];

  // Attach listeners for movement and resizing.
  attachResizeAndMovementListenersToElement(mapperInput, zOrderedElements);
  attachResizeAndMovementListenersToElement(mapperOutputReducerInput, zOrderedElements);
  attachResizeAndMovementListenersToElement(reducerOutput, zOrderedElements);
  attachResizeAndMovementListenersToElement(reducerChart, zOrderedElements);
  attachResizeAndMovementListenersToElement(errorsOutput, zOrderedElements);
  attachResizeAndMovementListenersToElement(nodesStatus, zOrderedElements);
  attachResizeAndMovementListenersToElement(tasksStatus, zOrderedElements);

  // Set the callback for drawing the node monitor chart.
  var nodesUrl = '$sintrServerURL/nodesStatus';
  // charts.setOnLoadCallback(allowInterop(() =>
  //     drawMonitorAsStackedBarChart(nodesStatus.querySelector('.contents'), ['ready', 'active'], () {
  //       return HttpRequest.getString(nodesUrl).then((String nodesStatusData) {
  //         return JSON.decode(nodesStatusData);
  //       });
  //     })));

  // Set the callback for drawing the task monitor chart.
  var tasksUrl = '$sintrServerURL/tasksStatus';
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
  querySelector('#add-nodule').onClick.listen((_) => addNewCodeEditorPanel());

  // Set callbacks for server API calls.
  querySelector('#localExec').onClick.listen((_) => _localExec());

  querySelector('#localReducer').onClick.listen((_) => _localReducer());

  querySelector('#localAll').onClick.listen((_) => _localAll());

  querySelector('#serverExec').onClick.listen((_) => _serverExec());

  querySelector('#getResults').onClick.listen((_) => _getResults());

  querySelector('#taskStats').onClick.listen((_) => _getTaskStats());

  // Add listener for the node count update
  querySelector('#set-node-count-button').onClick.listen((_) => _setNodeCount());

  // Get the starting code files from the server and display them in the UI.
  getDefaultSourceCodeFromServerAndAddToUI();

  // Get the sample input from the server and display it in the UI.
  getSampleInputFromServerAndAddToUI();

  initializeChartControls(querySelector('#reducer-chart').querySelector('.card-contents'));

  // Get the code mirror editor to offer completion and errors.
  var client = new SanitizingBrowserClient();
  dartServices = new dartservices.DartservicesApi(client, rootUrl: dartServicesURL);
  initKeyBindings();
}

initKeyBindings() {
  // No actions yet for Save and Run.
  keys.bind(['ctrl-s'], () {}, "Save", hidden: true);
  keys.bind(['ctrl-enter'], () {}, "Run");

  // No actions yet for Quick fixes and Completions.
  keys.bind(['alt-enter', 'ctrl-1'], () {}, "Quick fix");
  keys.bind(['ctrl-space', 'macctrl-space'], () {
    editors.forEach((DivElement editorContainer, Editor editor) {
      if (editor.hasFocus) {
        editor.showCompletions(autoInvoked: false);
      }
      return;
    });
  }, "Completion");
}


/// Rewrite the sources map to select the file to execute
Map<String, String> _selectExecFile(
  Map<String, String> sources, String sourceNameToExec) {

    const EXEC_NAME = "entry_point.dart"; // The file that will be run

    sources[EXEC_NAME] = sources[sourceNameToExec];
    sources.remove(sourceNameToExec);

    return sources;
  }

_localExec() {
  print ("localExec");
  var url = '$sintrServerURL/localExec';
  Map<String, String> sources = collectCodeSources();
  String input = querySelector('#map-input').querySelector('.card-contents').querySelector('pre').text;
  sources = _selectExecFile(sources, "entry_point_map.dart");

  Map<String, dynamic> message = {
    "sources": sources,
    "input": input,
  };
  var httpRequest = new HttpRequest();
  httpRequest
    ..open("POST", url)
    ..onLoad.listen((_) => logResponseInOutputPanel(httpRequest, 'map-output-reducer-input'))
    ..send(JSON.encode(message));
}

_localReducer() {
  print ("localReducer");

  var url = '$sintrServerURL/localReducer';
  Map<String, String> sources = collectCodeSources();
  String input = querySelector('#map-output-reducer-input').querySelector('.card-contents').querySelector('pre').text;
  sources = _selectExecFile(sources, "entry_point_reducer.dart");

  Map<String, dynamic> message = {
    "sources": sources,
    "input": input,
  };
  var httpRequest = new HttpRequest();
  httpRequest
    ..open("POST", url)
    ..onLoad.listen((_) => logResponseInOutputPanel(httpRequest, 'reducer-output'))
    ..send(JSON.encode(message));
}

_localAll() {
    print ("localExec-All");
    var url = '$sintrServerURL/localExec';
    Map<String, String> sources = collectCodeSources();
    String input = querySelector('#map-input').querySelector('.card-contents').querySelector('pre').text;
    sources = _selectExecFile(sources, "entry_point_map.dart");

    Map<String, dynamic> message = {
      "sources": sources,
      "input": input,
    };
    var httpRequest = new HttpRequest();
    httpRequest
      ..open("POST", url)
      ..onLoad.listen((_) {
        logResponseInOutputPanel(httpRequest, 'map-output-reducer-input');

        // Run the reducer
        print ("localReducer");

        var url = '$sintrServerURL/localReducer';
        Map<String, String> sources = collectCodeSources();
        String input = querySelector('#map-output-reducer-input').querySelector('.card-contents').querySelector('pre').text;
        sources = _selectExecFile(sources, "entry_point_reducer.dart");

        Map<String, dynamic> message = {
          "sources": sources,
          "input": input,
        };
        var httpRequestRed = new HttpRequest();
        httpRequestRed
          ..open("POST", url)
          ..onLoad.listen((_) => logResponseInOutputPanel(httpRequestRed, 'reducer-output'))
          ..send(JSON.encode(message));


      })
      ..send(JSON.encode(message));
  }

_serverExec() {
  var url = '$sintrServerURL/serverExec';
  Map<String, String> sources = collectCodeSources();
  String input = querySelector('#map-input').querySelector('.card-contents').querySelector('pre').text;
  String jobName = (querySelector('#server-job-name-textfield') as InputElement).value;
  sources = _selectExecFile(sources, "entry_point_map.dart");

  Map<String, dynamic> message = {
    "sources": sources,
    "input": [input],
    "jobName": jobName,
  };
  var httpRequest = new HttpRequest();
  httpRequest
    ..open("POST", url)
    ..onLoad.listen((_) => logResponseInOutputPanel(httpRequest, 'map-output-reducer-input'))
    ..send(JSON.encode(message));
}

_getResults() {
  var url = '$sintrServerURL/getResults';
  String jobName = (querySelector('#server-job-name-textfield') as InputElement).value;
  Map<String, dynamic> message = {
    "jobName": jobName,
  };
  var httpRequest = new HttpRequest();
  httpRequest
    ..open("POST", url)
    ..onLoad.listen((_) => logResponseInOutputPanel(httpRequest, 'map-output-reducer-input'))
    ..send(JSON.encode(message));
}

_getTaskStats() {
  var url = '$sintrServerURL/taskStats';
  var httpRequest = new HttpRequest();
  httpRequest
    ..open("POST", url)
    ..onLoad.listen((_) => logResponseInOutputPanel(httpRequest, 'map-output-reducer-input'))
    ..send(JSON.encode('taskStats'));
}

_setNodeCount() {
  String textfieldValue = "";
  try {
    textfieldValue = (querySelector('#node-count-textfield') as InputElement).value;
    int nodeCount = int.parse(textfieldValue);
    var httpRequest = new HttpRequest();
    httpRequest
      ..open("POST", "$sintrServerURL/$setNodeCountPath")
      ..onLoad.listen((event) {
        logResponseInOutputPanel(httpRequest, 'map-output-reducer-input');
        snackbar(httpRequest.responseText).show();
      })
      ..send(JSON.encode({'count': nodeCount}));
  } catch (e) {
    window.alert('Number of nodes must be a positive number, but you have entered \"$textfieldValue\".\n');
  }
}
