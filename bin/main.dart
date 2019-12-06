import 'dart:async';

import 'package:simplistic/simplistic.dart';

Future main(List<String> args) async {
  var context = parseArgs(args);
  var server = new SimpleServer(context);

  server.start();
}

