// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sintr_ui;

const pollInterval = const Duration(seconds: 5);

typedef void ResponseCallback(String responseText);

class Poller {
  Timer timer;
  String pollURL, updateURL;
  ResponseCallback callback;

  Poller(String pollURL, String updateURL, ResponseCallback callback)
      : this.pollURL = pollURL,
        this.updateURL = updateURL,
        this.callback = callback;

  startPolling() {
    // Cancel the previous timer, if there was any.
    cancelTimer();
    timer = new Timer.periodic(pollInterval, (timer) => pollAndUpdate());
  }

  cancelTimer() {
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
  }

  void pollAndUpdate() {
    HttpRequest.getString(pollURL).then((String isDone) {
      if (isDone == 'DONE') {
        cancelTimer();
      } else {
        HttpRequest.getString(updateURL).then((String response) {
          callback(response);
        });
      }
    });
  }
}
