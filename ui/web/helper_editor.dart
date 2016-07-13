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
