import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:sintr_live_common/logging_utils.dart' as logging;

// Run this from the root of the sintr_live checkout

String JOB_NAME = "sintr-interactive";

int port;

main(List<String> args) async {
  if (args.length != 1) {
    print ("Usage: sample_run.dart port");
    exit(1);
  }

  port = int.parse(args[0]);

  logging.setupLogging();

  String src = new File('infrastructure/lib/entry_point.dart').readAsStringSync();

  var sources = { "entry_point.dart" : src };
  var inputs = new List.generate(1000, (i) => "$i");//  //["0", "1", "2"];

  for (var input in inputs) {
    await _sendRequest(sources, input);
  }
}

_sendRequest(Map<String, String> sources, String input) async {
  var request = await new HttpClient().post(
      InternetAddress.LOOPBACK_IP_V4.host, port, '/');
      // request.headers.contentType = ContentType.JSON;
  await request.write(JSON.encode({
    "sources" : sources,
    "input" : input
  }));

  await new Future.delayed(new Duration(milliseconds: 20));

  HttpClientResponse response = await request.close();
  await for (var contents in response.transform(UTF8.decoder)) {

      // await new Future.delayed(new Duration(milliseconds: 5));

       print(contents);
    }

}
