import 'dart:convert';
import 'dart:io';

int serverPort;

main(List<String> args) async {
  if (args.length != 1) {
    print ("Usage: server_based_test.dart fe_server_port");
    exit(1);
  }

  serverPort = int.parse(args[0]);
  await _testLocal();
}


_testLocal() async {

  print ("About to test taskStats");
  // Test getting the local statistics for the tasks
  await _sendMessage("taskStats", {});

  // Test executing a script 100x locally

  String src = new File('infrastructure/lib/entry_point.dart').readAsStringSync();

  print ("About to test localExec");

  var sources = { "entry_point.dart" : src };
  var inputs = new List.generate(100, (i) => "$i");//  //["0", "1", "2"];

  for (var input in inputs) {
    await _sendMessage("localExec", {"sources" : sources , "input" : input});
  }

}

_sendMessage(String action, var requestStructure) async {

  var request = await new HttpClient().post(
      InternetAddress.LOOPBACK_IP_V4.host, serverPort, action);
  await request.write(JSON.encode(requestStructure));

  // await new Future.delayed(new Duration(milliseconds: 20));

  HttpClientResponse response = await request.close();
  await for (var contents in response.transform(UTF8.decoder)) {
       print(contents);
    }

}
