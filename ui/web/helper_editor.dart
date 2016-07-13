// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sintr_ui;

_handleAutoCompletion(Editor editor, KeyboardEvent e) {
  if (editor.completionActive || !editor.hasFocus) {
    return;
  }
  if (editor.hasFocus) {
    if (e.keyCode == KeyCode.PERIOD) {
      print (e.keyCode);
      editor.showCompletions(autoInvoked: true);
    }
  }

  // RegExp exp = new RegExp(r"[A-Z]");
  // if (exp.hasMatch(new String.fromCharCode(e.keyCode))) {
  //   editor.showCompletions(autoInvoked: true);
  // }
}

Future _analysisRequest;

/// Perform static analysis of the source code. Return whether the code
/// analyzed cleanly (had no errors or warnings).
Future<bool> _performAnalysis(Editor editor) {
  dartservices.SourceRequest input = new dartservices.SourceRequest()..source = editor.document.value;

  Lines lines = new Lines(input.source);

  Future request = dartServices.analyze(input).timeout(serviceCallTimeout);
  _analysisRequest = request;

  return request.then((dartservices.AnalysisResults result) {
    // Discard if we requested another analysis.
    if (_analysisRequest != request) return false;

    // Discard if the document has been mutated since we requested analysis.
    if (input.source != editor.document.value) return false;

    editor.document
        .setAnnotations(result.issues.map((dartservices.AnalysisIssue issue) {
      int startLine = lines.getLineForOffset(issue.charStart);
      int endLine = lines.getLineForOffset(issue.charStart + issue.charLength);

      Position start = new Position(startLine, issue.charStart - lines.offsetForLine(startLine));
      Position end = new Position(
          endLine,
          issue.charStart +
              issue.charLength -
              lines.offsetForLine(startLine));

      return new Annotation(issue.kind, issue.message, issue.line,
          start: start, end: end);
    }).toList());

    bool hasErrors = result.issues.any((issue) => issue.kind == 'error');
    bool hasWarnings = result.issues.any((issue) => issue.kind == 'warning');

    return hasErrors == false && hasWarnings == false;
  }).catchError((e, st) {
    editor.document.setAnnotations([]);
    print(e);
    print(st);
  });
}

// See https://github.com/dart-lang/dart-pad/blob/master/lib/services/common.dart
class Lines {
  List<int> _starts = [];

  Lines(String source) {
    List<int> units = source.codeUnits;
    bool nextIsEol = true;
    for (int i = 0; i < units.length; i++) {
      if (nextIsEol) {
        nextIsEol = false;
        _starts.add(i);
      }
      if (units[i] == 10) nextIsEol = true;
    }
  }

  /// Return the 0-based line number.
  int getLineForOffset(int offset) {
    if (_starts.isEmpty) return 0;
    for (int i = 1; i < _starts.length; i++) {
      if (offset < _starts[i]) return i - 1;
    }
    return _starts.length - 1;
  }

  int offsetForLine(int line) {
    assert(line >= 0);
    if (_starts.isEmpty) return 0;
    if (line >= _starts.length) line = _starts.length - 1;
    return _starts[line];
  }
}

// When sending requests from a browser we sanitize the headers to avoid
// client side warnings for any blacklisted headers.
class SanitizingBrowserClient extends BrowserClient {
  // The below list of disallowed browser headers is based on list at:
  // http://www.w3.org/TR/XMLHttpRequest/#the-setrequestheader()-method
  static const List<String> disallowedHeaders = const [
    'accept-charset',
    'accept-encoding',
    'access-control-request-headers',
    'access-control-request-method',
    'connection',
    'content-length',
    'cookie',
    'cookie2',
    'date',
    'dnt',
    'expect',
    'host',
    'keep-alive',
    'origin',
    'referer',
    'te',
    'trailer',
    'transfer-encoding',
    'upgrade',
    'user-agent',
    'via'
  ];

  /// Strips all disallowed headers for an HTTP request before sending it.
  Future<StreamedResponse> send(BaseRequest request) {
    for (String headerKey in disallowedHeaders) {
      request.headers.remove(headerKey);
    }

    // Replace 'application/json; charset=utf-8' with text/plain. This will
    // avoid the browser sending an OPTIONS request before the actual POST (and
    // introducing an additional round trip between the client and the server).
    request.headers['Content-Type'] = 'text/plain; charset=utf-8';

    return super.send(request);
  }
}
