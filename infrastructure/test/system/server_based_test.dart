import 'dart:async';
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
  Stopwatch sw = new Stopwatch()..start();


  // print ("About to test taskStats");
  // Test getting the local statistics for the tasks
  // await _sendMessage("taskStats", {});

  // Test executing a script 100x locally

  String mapSrc = new File('infrastructure/lib/entry_point_map.dart').readAsStringSync();
  String reduceSrc = new File('infrastructure/lib/entry_point_reducer.dart').readAsStringSync();

  print ("About to test localExec");

  var mapSources = { "entry_point.dart" : mapSrc };
  var reduceSources = { "entry_point.dart" : reduceSrc };
  // var inputs = new List.generate(100, (i) => "$i");//  //["0", "1", "2"];

//   var input = "/Users/lukechurch/t8.shakespeare.txt";
//
//   // Break the input into 10000 lines chunks
//   List<String> inputs = [];
//
//   List<String> fileLines = new File(input).readAsLinesSync();
//
//   int i = 0;
//   StringBuffer sb = new StringBuffer();
//
//   for (String ln in fileLines) {
//     if (++i % 1000 == 0) {
//       inputs.add(sb.toString());
//       sb.clear();
//     }
//     sb.writeln(ln);
//   }
//
//   // Creating lines
//   // print (inputs);
//   print ("About to create tasks: ${inputs.length}");
//
//
//   // Create the corresponding bulk tasks
//   var execResult = await _sendMessage("severExec",
//   {"sources" : mapSources,
//   "input" : inputs,
//   "jobName" : "shakespeare_wrd_map"
// });

var getResults = await _sendMessage("getResults",
  {"jobName" : "shakespeare_wrd_map"});

  // This is a disgusting mess of JSON

  List<String> resultsList = JSON.decode(getResults);
  for (String results in resultsList) {
    var kvs = JSON.decode(JSON.decode(results)["result"]);
    // print (JSON.d kvs.runtim/eType);
    for (var kv in kvs) {
      print (kv);
    }
    // print ();
  }

  // print (getResults);






  // print ("Starting map exec: ${sw.elapsedMilliseconds}");

    // var execResult = await _sendMessage("localExec", {"sources" : mapSources , "input" : input});

    // print ("Starting map exec: ${sw.elapsedMilliseconds}");

    //
    // var decoded = JSON.decode(execResult);
    // var result = decoded["result"];
    // var error = decoded["error"];
    // var st = decoded["stacktrace"];
    //
    // // Group by key
    //
    // Map reduceTargets = {};
    //
    // List kvs = JSON.decode(result);
    // for (Map kv in kvs) {
    //   var key = kv.keys.first;
    //   var value = kv.values.first;
    //
    //   reduceTargets.putIfAbsent(key, () => []);
    //   reduceTargets[key].add(value);
    // }
    //
    // Map results = {};
    //
    // for (var k in reduceTargets.keys) {
    //
    //   var resultCoded = await _sendMessage("localExec", {"sources" : reduceSources ,
    //   "input" : JSON.encode(
    //     {"key" : k, "values" : reduceTargets[k]}
    //   )});
    //
    //   var result = JSON.decode(resultCoded)["result"];
    //
    //   results[k] = result;
    //   print ("$k: $result");
    //
    //
    // }




  // }

}

Future<String> _sendMessage(String action, var requestStructure) async {
  await new Future.delayed(new Duration(milliseconds: 20));

  var request = await new HttpClient().post(
      InternetAddress.LOOPBACK_IP_V4.host, serverPort, action);
  await request.write(JSON.encode(requestStructure));

  // await new Future.delayed(new Duration(milliseconds: 20));

  HttpClientResponse response = await request.close();

  String result = await response.transform(UTF8.decoder).join();
  return result;
}
