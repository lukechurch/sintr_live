import 'dart:io';
import 'package:sintr_live_infrastructure/evaluator.dart' as eval;

main() async {
  String src = new File('../lib/entry_point.dart').readAsStringSync();

  for (int i = 0; i < 1000; i++) {
    print(await eval.eval({ "entry_point.dart" : src } , "test-msg-$i"));
    // await eval.eval({ "entry_point.dart" : src } , "test-msg2");
  }


}
