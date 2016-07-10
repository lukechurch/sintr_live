// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'utils.dart';

final HOST = "127.0.0.1"; // eg: localhost
final PORT = 11001;
final DATA_FOLDER = "bin";

void main() {
  HttpServer.bind(HOST, PORT).then((server) {
    server.listen((HttpRequest request) {
      switch (request.method) {
        case "GET":
          handleGet(request);
          break;
        case "POST":
          handlePost(request);
          break;
        case "OPTIONS":
          handleOptions(request);
          break;
        default:
          defaultHandler(request);
      }
    }, onError: printError);

    print("Listening for GET and POST on http://$HOST:$PORT");
  }, onError: printError);
}

int responsePart = 0;
int totalResponseParts = results.length;
int nodesStatusStartSlope = 3;
int nodesStatusEndSlope = 10;
int tasksStatusStartSlope = 7;
int nodes = 500;
int tasks = 4000;
bool taskDone = false;

Random rand = new Random();

void handleGet(HttpRequest req) {
  HttpResponse res = req.response;
  print("${req.method}: ${req.uri.path}");
  addCorsHeaders(res);

  switch (req.uri.path) {
    case '/sampleInput':
      res.add(UTF8.encode(JSON.encode(sampleInput)));
      res.close();
      break;
    case '/sources':
      Map<String, String> sources = {};
      sources["pubspec.yaml"] = PUBSPEC_SRC;
      sources["entry.dart"] = SRC;
      res.add(UTF8.encode(JSON.encode(sources)));
      res.close();
      break;
    case '/nodesStatus':
      var nodesStatus = {'ready': 0, 'active': 0};
      if (responsePart == 0) {
        nodesStatus['active'] = 0;
        nodesStatus['ready'] = nodes;
      } else if (responsePart < nodesStatusStartSlope) {
        nodesStatus['active'] = nodes * responsePart ~/ nodesStatusStartSlope;
        nodesStatus['ready'] = nodes - nodesStatus['active'];
      } else if (responsePart > totalResponseParts - nodesStatusEndSlope) {
        var remainingResponseParts = totalResponseParts - responsePart;
        nodesStatus['active'] = nodes * remainingResponseParts ~/ nodesStatusEndSlope;
        nodesStatus['ready'] = nodes - nodesStatus['active'];
      } else {
        nodesStatus['active'] = nodes - 5 + rand.nextInt(5);
        nodesStatus['ready'] = nodes - nodesStatus['active'];
      }
      res.add(UTF8.encode(JSON.encode(nodesStatus)));
      res.close();
      break;
    case '/tasksStatus':
      var tasksStatus = {'ready': 0, 'active': 0, 'done': 0, 'failed': 0};
      if (responsePart == 0 && taskDone == false) {
        tasksStatus['ready'] = tasks;
      } else if (responsePart == 0 && taskDone == false) {
        tasksStatus['done'] = tasks;
      } else {
        tasksStatus['active'] = tasks * responsePart ~/ totalResponseParts;
        tasksStatus['ready'] = tasks - tasksStatus['active'];
        if (tasksStatus['active'] > nodes) {
          tasksStatus['done'] = tasksStatus['active'] - nodes;
          tasksStatus['active'] = nodes;
        }
      }
      res.add(UTF8.encode(JSON.encode(tasksStatus)));
      res.close();
      break;
    case '/isDone':
      if (responsePart == totalResponseParts) {
        // Mock up the need for multiple requests to get all data
        res.add(UTF8.encode("DONE"));
        res.close();
        taskDone = true;
        responsePart = 0;
      } else {
        // Mock up the need for multiple requests to get all data
        res.add(UTF8.encode("NOPE"));
        res.close();
      }
      break;
    case "/results":
      var dataToSend = results[responsePart];
      res.add(UTF8.encode(JSON.encode(dataToSend)));
      res.close();
      responsePart++;
      break;
    default:
      res.statusCode = 404;
      res.close();
    }
  }

handlePost(HttpRequest req) {
  HttpResponse res = req.response;
  print("${req.method}: ${req.uri.path}");

  addCorsHeaders(res);

  req.listen((List<int> buffer) {
    String requestString = UTF8.decode(buffer);
    var json = JSON.decode(requestString);
    switch (req.uri.path) {
      case "/runCode":
        // Pretend to run the code...

        // Re-initialize the response data
        responsePart = 0;
        taskDone = false;

        // Reply and say that it's all good.
        res.add(UTF8.encode("OK"));
        res.close();
        break;
      case "/setNodeCount":
        String requestString = UTF8.decode(buffer);
        var json = JSON.decode(requestString);
        int count = json["count"];
        String response = count == 1000 ? "Node count set" : "Unable to set node count";
        res.write(response);
        res.close();
        break;
      case "/localExec":
        String response = "localExec: Received ${json['sources'].length} source files to analyse.";
        res.write(response);
        res.close();
        break;
      case "/localReducer":
        String response = "localReducer: Received ${json['sources'].length} source files to analyse.";
        res.write(response);
        res.close();
        break;
      case "/serverExec":
        Map<String, String> sources = json["sources"];
        List<String> input = json["input"];
        String jobName = json["jobName"];
        String response = "serverExec: Received ${sources.length} source files and ${input.length} inputs to analyse .";
        res.write(response);
        res.close();
        break;
      case "/getResults":
        String jobName = json["jobName"];
        String response = "getResults: Received job ${jobName}.";
        res.write(response);
        res.close();
        break;
      case "/taskStats":
        res.write("taskStats request received");
        res.close();
        break;
      default:
        res.statusCode = 404;
        res.close();
    }
  }, onError: printError);
}

/**
 * Add Cross-site headers to enable accessing this server from pages
 * not served by this server
 *
 * See: http://www.html5rocks.com/en/tutorials/cors/
 * and http://enable-cors.org/server.html
 */
void addCorsHeaders(HttpResponse res) {
  res.headers.add("Access-Control-Allow-Origin", "*");
  res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.headers.add("Access-Control-Allow-Headers",
      "Origin, X-Requested-With, Content-Type, Accept");
}

void handleOptions(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  print("${req.method}: ${req.uri.path}");
  res.statusCode = HttpStatus.NO_CONTENT;
  res.close();
}

void defaultHandler(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  res.statusCode = HttpStatus.NOT_FOUND;
  res.write("Not found: ${req.method}, ${req.uri.path}");
  res.close();
}

void printError(error) => print(error);





// Sources

final SRC = """
import 'dart:math';

int hogPresenceThreshold = 5.0;

Map<int, bool> map(String filename) {
  List<List<String>> tokens = await tokenizeFileByLines(filename);
  Map<int, bool> hogPresence = {};
  tokens.forEach((line) {
    var timestamp = int.parse(line[0]);
    var gx = double.parse(line[1]);
    var gy = double.parse(line[2]);
    var gz = double.parse(line[3]);
    var magnitude = sqrt(gx * gx + gy * gy + gz * gz);
    if (magnitude > hogPresenceThreshold) {
      hogPresence[timestamp] = true;
    } else {
      hogPresence[timestamp] = false;
    }
  });
  return hogPresence;
}

Map<bool, int> reduce(Map<int, bool> timestampPresence, Map<bool, int> partialCounts) {
  timestampPresence.forEach((int timestamp, bool presence) {
    partialCounts[presence] = partialCounts[presence] + 1;
  });
  return partialCounts;
}
""";

final PUBSPEC_SRC = """
name: 'sintr_ui'
version: 0.0.1
description: sample

environment:
  sdk: '>=1.0.0 <2.0.0'

dependencies:
  uuid: '>=0.5.0 <0.6.0'

""";
