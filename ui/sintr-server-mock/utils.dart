// DEPRICATED PENDING REMOVAL

// // Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.
//
// library utils;
//
// var sampleInput = {
//   '2016.02.01.csv':
//       """1454284800,   9.15,  0.68,  4.92
// 1454284801,   10.54, 0.76,  4.27
// 1454284802,   11.76, 0.81,  4.68
// 1454284803,   10.65, 0.23,  4.69
// 1454284804,   12.96, 0.65,  5.33""",
//   '2016.02.02.csv':
//       """1454371200,   9.15,  0.68,  4.92
// 1454371201,   10.54, 0.76,  4.27
// 1454371202,   11.76, 0.81,  4.68
// 1454371203,   10.54, 0.76,  4.27
// 1454371204,   10.65, 0.23,  4.69
// 1454371205,   12.96, 0.65,  5.33""",
//   '2016.02.03.csv':
//       """1454457600,   9.15,  0.68,  4.92
// 1454457601,   10.54, 0.76,  4.27
// 1454457602,   11.76, 0.81,  4.68
// 1454457603,   10.65, 0.23,  4.69
// 1454457604,   10.54, 0.76,  4.27
// 1454457605,   11.76, 0.81,  4.68
// 1454457606,   12.96, 0.65,  5.33""",
//   '2016.02.04.csv':
//       """1454544000,   9.15,  0.68,  4.92
// '1454544001,   10.54, 0.76,  4.27
// '1454544002,   11.76, 0.81,  4.68
// '1454544003,   10.65, 0.23,  4.69
// '1454544004,   12.96, 0.65,  5.33""",
// };
//
// var resultsPart1 = {
//   'data': {
//     '1459289173': true,
//     '1459289175': true,
//     '1459289177': true,
//     '1459289179': true,
//     '1459289181': true,
//     '1459289183': false,
//     '1459289185': false,
//     '1459289187': false,
//     '1459289189': false,
//     '1459289191': false,
//     '1459289193': false,
//     '1459289195': false,
//     '1459289197': false,
//     '1459289199': false,
//     '1459289201': false,
//     '1459289203': false,
//     '1459289205': false,
//     '1459289207': false,
//     '1459289209': false,
//     '1459289211': false,
//     '1459289213': false,
//     '1459289215': false,
//     '1459289217': true,
//     '1459289219': true,
//     '1459289221': true,
//     '1459289223': true,
//     '1459289225': true,
//   },
//   'errors': {
//     """type 'double' is not a subtype of type 'int' of 'b'.
// at dart.wrapException (<anonymous>:2015:17)
// at dart._sendMessage (<anonymous>:5500:17)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5710:13)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at Analysis.run\$1 (<anonymous>:5608:14)
// at eval (eval at <anonymous> (unknown source), <anonymous>:2:38)
// at invokeClosure_closure0.dart.invokeClosure_closure0.call\$0 (<anonymous>:2909:41)
// at _IsolateContext.dart._IsolateContext.eval\$1 (<anonymous>:1223:25)
// at dart._callInIsolate (<anonymous>:867:28)
// at dart.invokeClosure (<anonymous>:2161:18)""": 4,
//
//     """Bad state: Division by zero.
// at dart.wrapException (<anonymous>:2015:17)
// at dart._sendMessage (<anonymous>:5500:17)
// at dart.compute (<anonymous>:5568:9)
// at dart.compute (<anonymous>:5572:11)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5707:11)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5711:18)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at AnalysisSystem.analyze\$1 (<anonymous>:5608:14)
// at eval (eval at <anonymous> (unknown source), <anonymous>:2:38)
// at invokeClosure_closure0.dart.invokeClosure_closure0.call\$0 (<anonymous>:2909:41)""": 1,
//
//     """RangeError: Value not in range: 5
// at dart.wrapException (<anonymous>:2015:17)
// at dart._sendMessage (<anonymous>:5500:17)
// at dart.compute (<anonymous>:5568:9)
// at dart.compute (<anonymous>:5572:11)
// at dart.compute (<anonymous>:5572:11)
// at dart.compute (<anonymous>:5572:11)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5707:11)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5711:18)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)""": 4,
//   }
// };
//
// var resultsPart2 = {
//   'data': {
//     '1459289227': true,
//     '1459289229': true,
//     '1459289231': true,
//     '1459289233': true,
//     '1459289235': true,
//     '1459289237': true,
//     '1459289239': true,
//     '1459289241': false,
//     '1459289243': false,
//     '1459289245': false,
//     '1459289247': false,
//     '1459289249': false,
//     '1459289251': false,
//     '1459289253': false,
//     '1459289255': false,
//     '1459289257': true,
//     '1459289259': true,
//     '1459289261': true,
//   },
//   'errors': {
//     """Bad state: Division by zero.
// at dart.wrapException (<anonymous>:2015:17)
// at dart._sendMessage (<anonymous>:5500:17)
// at dart.compute (<anonymous>:5568:9)
// at dart.compute (<anonymous>:5572:11)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5707:11)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5711:18)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at AnalysisSystem.analyze\$1 (<anonymous>:5608:14)
// at eval (eval at <anonymous> (unknown source), <anonymous>:2:38)
// at invokeClosure_closure0.dart.invokeClosure_closure0.call\$0 (<anonymous>:2909:41)""": 1,
//   }
// };
//
// var resultsPart3 = {
//   'data': {
//     '1459289263': true,
//     '1459289275': true,
//     '1459289277': true,
//     '1459289279': true,
//     '1459289281': true,
//     '1459289283': true,
//     '1459289285': true,
//     '1459289287': true,
//     '1459289289': true,
//     '1459289291': true,
//     '1459289293': false,
//     '1459289295': false,
//     '1459289297': false,
//     '1459289299': false,
//     '1459289301': false,
//     '1459289303': false,
//     '1459289305': false,
//     '1459289307': false,
//     '1459289309': false,
//     '1459289311': false,
//     '1459289313': false,
//     '1459289315': false,
//     '1459289317': false,
//     '1459289319': false,
//     '1459289321': false,
//     '1459289323': false,
//     '1459289325': false,
//   },
//   'errors': {
//     """type 'double' is not a subtype of type 'int' of 'b'.
// at dart.wrapException (<anonymous>:2015:17)
// at dart._sendMessage (<anonymous>:5500:17)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5710:13)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at AnalysisSystem.analyze\$1 (<anonymous>:5608:14)
// at eval (eval at <anonymous> (unknown source), <anonymous>:2:38)
// at invokeClosure_closure0.dart.invokeClosure_closure0.call\$0 (<anonymous>:2909:41)
// at _IsolateContext.dart._IsolateContext.eval\$1 (<anonymous>:1223:25)
// at dart._callInIsolate (<anonymous>:867:28)
// at dart.invokeClosure (<anonymous>:2161:18)""": 2,
//
//     """RangeError: Value not in range: 5
// at dart.wrapException (<anonymous>:2015:17)
// at dart._sendMessage (<anonymous>:5500:17)
// at dart.compute (<anonymous>:5568:9)
// at dart.compute (<anonymous>:5572:11)
// at dart.compute (<anonymous>:5572:11)
// at dart.compute (<anonymous>:5572:11)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5707:11)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5711:18)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)""": 2,
//   }
// };
//
// var resultsPart4 = {
//   'data': {
//     '1459289327': true,
//     '1459289329': true,
//     '1459289331': true,
//     '1459289333': true,
//     '1459289335': true,
//     '1459289337': true,
//     '1459289339': true,
//     '1459289341': true,
//     '1459289343': true,
//     '1459289345': true,
//     '1459289347': true,
//     '1459289349': true,
//     '1459289351': true,
//     '1459289353': true,
//     '1459289355': true,
//     '1459289357': true,
//     '1459289359': true,
//     '1459289361': true,
//     '1459289363': true,
//     '1459289365': true,
//     '1459289367': true,
//     '1459289369': true,
//     '1459289371': true,
//     '1459289373': true,
//     '1459289375': true,
//     '1459289377': true,
//     '1459289379': true,
//     '1459289381': true,
//     '1459289383': true,
//     '1459289385': true,
//     '1459289387': true,
//     '1459289389': true,
//   },
//   'errors': {
//     """type 'double' is not a subtype of type 'int' of 'b'.
// at dart.wrapException (<anonymous>:2015:17)
// at dart._sendMessage (<anonymous>:5500:17)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5710:13)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at AnalysisSystem.analyze\$1 (<anonymous>:5608:14)
// at eval (eval at <anonymous> (unknown source), <anonymous>:2:38)
// at invokeClosure_closure0.dart.invokeClosure_closure0.call\$0 (<anonymous>:2909:41)
// at _IsolateContext.dart._IsolateContext.eval\$1 (<anonymous>:1223:25)
// at dart._callInIsolate (<anonymous>:867:28)
// at dart.invokeClosure (<anonymous>:2161:18)""": 2,
//
//     """Bad state: Division by zero.
// at dart.wrapException (<anonymous>:2015:17)
// at dart._sendMessage (<anonymous>:5500:17)
// at dart.compute (<anonymous>:5568:9)
// at dart.compute (<anonymous>:5572:11)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5707:11)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5711:18)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at AnalysisSystem.analyze\$1 (<anonymous>:5608:14)
// at eval (eval at <anonymous> (unknown source), <anonymous>:2:38)
// at invokeClosure_closure0.dart.invokeClosure_closure0.call\$0 (<anonymous>:2909:41)""": 5,
//   }
// };
//
//
// var resultsPart5 = {
//   'data': {
//     '1459289391': true,
//     '1459289393': true,
//     '1459289395': true,
//     '1459289397': true,
//     '1459289399': true,
//     '1459289401': true,
//     '1459289403': true,
//     '1459289405': true,
//     '1459289407': true,
//     '1459289409': true,
//     '1459289411': true,
//     '1459289413': true,
//     '1459289415': true,
//     '1459289417': true,
//     '1459289419': true,
//     '1459289421': true,
//     '1459289423': true,
//     '1459289425': true,
//     '1459289427': true,
//     '1459289429': true,
//     '1459289431': true,
//     '1459289433': true,
//     '1459289435': true,
//     '1459289437': true,
//     '1459289439': true,
//     '1459289441': true,
//     '1459289443': true,
//     '1459289445': true,
//     '1459289447': true,
//     '1459289449': true,
//     '1459289451': true,
//     '1459289453': true,
//     '1459289455': true,
//     '1459289457': true,
//     '1459289459': true,
//   },
//   'errors': {
//     """Bad state: Division by zero.
// at dart.wrapException (<anonymous>:2015:17)
// at dart._sendMessage (<anonymous>:5500:17)
// at dart.compute (<anonymous>:5568:9)
// at dart.compute (<anonymous>:5572:11)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5707:11)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5711:18)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at AnalysisSystem.analyze\$1 (<anonymous>:5608:14)
// at eval (eval at <anonymous> (unknown source), <anonymous>:2:38)
// at invokeClosure_closure0.dart.invokeClosure_closure0.call\$0 (<anonymous>:2909:41)""": 4,
//     """RangeError: Value not in range: 5
// at dart.wrapException (<anonymous>:2015:17)
// at dart._sendMessage (<anonymous>:5500:17)
// at dart.compute (<anonymous>:5568:9)
// at dart.compute (<anonymous>:5572:11)
// at dart.compute (<anonymous>:5572:11)
// at dart.compute (<anonymous>:5572:11)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5707:11)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)
// at WorkerNode.dart.WorkerNode.runChildren\$2 (<anonymous>:5711:18)
// at WorkerNode.dart.WorkerNode.analyze\$2 (<anonymous>:5651:14)""": 9,
//   }
// };
//
// List parts = <Map>[
//   resultsPart1, resultsPart2, resultsPart3, resultsPart4, resultsPart5,
//   resultsPart1, resultsPart1, resultsPart2, resultsPart5, resultsPart1,
//   resultsPart5, resultsPart3, resultsPart3, resultsPart2, resultsPart4,
//   resultsPart1, resultsPart2, resultsPart2, resultsPart5, resultsPart3,
//   resultsPart3, resultsPart3, resultsPart4, resultsPart4, resultsPart5];
//
// List<Map> _results;
//
// List<Map> get results {
//   if (_results != null) {
//     return _results;
//   }
//
//   _results = [];
//   int timestamp = 1454284800;
//   parts.forEach((Map part) {
//     Map<String, bool> dataMap = part['data'];
//     Map<String, bool> newDataMap = {};
//     var keys = dataMap.keys.toList();
//     keys.sort();
//     keys.forEach((key) => newDataMap[(timestamp++).toString()] = dataMap[key]);
//     _results.add({'data': newDataMap, 'errors': part['errors']});
//   });
//   print (_results);
//   return _results;
// }
