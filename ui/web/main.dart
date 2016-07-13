// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sintr_ui;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:mdl/mdl.dart';
import 'package:plotly/plotly.dart' as plotly;
import 'package:uuid/uuid.dart';

import 'package:sintr_ui/editing/editor.dart';
import 'package:sintr_ui/editing/editor_codemirror.dart';
import 'package:sintr_ui/editing/keys.dart';

import 'package:sintr_ui/in_memory_shuffler.dart' as shuffler;

part 'helper_layout.dart';
part 'helper_server_poller.dart';
part 'utils.dart';


DivElement mapInput;
DivElement mapOutputReducerInput;
DivElement reducerOutput;
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
final String dartServicesURL = 'http://127.0.0.1:8990';
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
  // TODO(mariana) Should be replaced with calls to local or remote exec.
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

    String jsonDecoded = JSON.decode(sampleInput);
    // rawInput.querySelector('.card-contents').innerHtml =
    //     inputMapStringify(JSON.decode(sampleInput));
    mapInput.querySelector('.card-contents').querySelector('pre').text =
        "$jsonDecoded";
  });
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
  mapInput = querySelector('#map-input');
  mapOutputReducerInput = querySelector('#map-output-reducer-input');
  reducerOutput = querySelector('#reducer-output');
  outputHistogram = querySelector('#output-histogram');
  errorsOutput = querySelector('#errors-output');
  nodesStatus = querySelector('#nodes-status');
  tasksStatus = querySelector('#tasks-status');

  // Initialize the neighbours of the elements of the UI.
  connections[mapInput] = new Neighbours();
  connections[mapOutputReducerInput] = new Neighbours();
  connections[reducerOutput] = new Neighbours();
  connections[outputHistogram] = new Neighbours();
  connections[errorsOutput] = new Neighbours();
  connections[nodesStatus] = new Neighbours();
  connections[tasksStatus] = new Neighbours();

  // Attach listeners for the title bar buttons.
  attachTitleBarButtonsListeners(mapInput);
  attachTitleBarButtonsListeners(mapOutputReducerInput);
  attachTitleBarButtonsListeners(reducerOutput);
  attachTitleBarButtonsListeners(outputHistogram);
  attachTitleBarButtonsListeners(errorsOutput);
  attachTitleBarButtonsListeners(nodesStatus);
  attachTitleBarButtonsListeners(tasksStatus);

  // Set the order in which things are displayed on the screen.
  // This matches initially with the order in the DOM.
  zOrderedElements = [mapInput, mapOutputReducerInput, reducerOutput, outputHistogram, errorsOutput, nodesStatus, tasksStatus];

  // Attach listeners for movement and resizing.
  attachMovementListener(mapInput, zOrderedElements);
  attachMovementListener(mapOutputReducerInput, zOrderedElements);
  attachMovementListener(reducerOutput, zOrderedElements);
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

  // Set callbacks for server API calls.
  querySelector('#localExec').onClick.listen((MouseEvent event) {
   _localExec();
  });

  querySelector('#localReducer').onClick.listen((MouseEvent event) async {
    await _localReducer();
  });

  querySelector('#serverExec').onClick.listen((MouseEvent event) {
    var url = '$dartServicesURL/serverExec';
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
  });

  querySelector('#getResults').onClick.listen((MouseEvent event) {
    var url = '$dartServicesURL/getResults';
    String jobName = (querySelector('#server-job-name-textfield') as InputElement).value;
    Map<String, dynamic> message = {
      "jobName": jobName,
    };
    var httpRequest = new HttpRequest();
    httpRequest
      ..open("POST", url)
      ..onLoad.listen((_) => logResponseInOutputPanel(httpRequest, 'map-output-reducer-input'))
      ..send(JSON.encode(message));
  });

  querySelector('#taskStats').onClick.listen((MouseEvent event) {
    var url = '$dartServicesURL/taskStats';
    var httpRequest = new HttpRequest();
    httpRequest
      ..open("POST", url)
      ..onLoad.listen((_) => logResponseInOutputPanel(httpRequest, 'map-output-reducer-input'))
      ..send(JSON.encode('taskStats'));
  });

  // Add listener for the node count update
  querySelector('#set-node-count-button').onClick.listen((_) {
    String textfieldValue = "";
    try {
      textfieldValue = (querySelector('#node-count-textfield') as InputElement).value;
      int nodeCount = int.parse(textfieldValue);
      var httpRequest = new HttpRequest();
      httpRequest
        ..open("POST", "$dartServicesURL/$setNodeCountPath")
        ..onLoad.listen((event) {
          logResponseInOutputPanel(httpRequest, 'map-output-reducer-input');
          snackbar(httpRequest.responseText).show();
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


/// Rewrite the sources map to select the file to execute
Map<String, String> _selectExecFile(
  Map<String, String> sources, String sourceNameToExec) {

    const EXEC_NAME = "entry_point.dart"; // The file that will be run

    sources[EXEC_NAME] = sources[sourceNameToExec];
    sources.remove(sourceNameToExec);

    return sources;
  }

_localExec() async {
  var url = '$dartServicesURL/localExec';
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

_localReducer() async {
  var url = '$dartServicesURL/localReducer';
  Map<String, String> sources = collectCodeSources();

  // Output from the local mapper
  String input = querySelector('#map-output-reducer-input').querySelector('.card-contents').querySelector('pre').text;
  List<Map> kvs = JSON.decode(input);
  Map keyToValueList = shuffler.shuffle(kvs);

  sources = _selectExecFile(sources, "entry_point_reducer.dart");

  List<Map> dataSeenSoFar = [];

  int updateUIStep = 50;
  int step = 0;
  for (var k in keyToValueList.keys) {
    var values = keyToValueList[k];

    Map<String, dynamic> message = {
      "sources": sources,
      "input":
        JSON.encode( {k : values} )
    };

    // k, values
    var httpRequest = new HttpRequest();
    httpRequest.open("POST", url);
    httpRequest.onLoad.listen((_) {
      String result = httpRequest.responseText;
      var lst = JSON.decode(JSON.decode(result)["result"]);
      dataSeenSoFar.addAll(lst);
      step++;
      print(step);
      if (step % updateUIStep == 0 || step == keyToValueList.length) {
        logResponseInOutputPanelLst(dataSeenSoFar, 'reducer-output');
      }
    });
    httpRequest.send(JSON.encode(message));

    // await new Future.delayed(const Duration(milliseconds: 10));
  }
}
