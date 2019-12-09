import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'pages.dart';

SecurityContext parseArgs(List<String> args) {
  ArgResults results;
  SecurityContext context;

  ArgParser parser = new ArgParser();
  parser..addOption('cert', abbr: 'c', help:
  'Path to the security certificate chain (preferrably PEM format).')
    ..addOption('key', abbr: 'k', help:
    'Path to the key file for the certificate chain (preferrably in PEM format).')
    ..addOption('password', abbr: 'p', help:
    'Password required for security key. Omit for no (null) password.');

  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    print(e.message);
    printHelp();
    exit(1);
  }

  if (results['cert'] == null || results['key'] == null) {
    print('Missing required aregument.');
    printHelp();
    exit(1);
  }

  var cert = results['cert'];
  var key = results['key'];

  try {
    context = new SecurityContext()
      ..useCertificateChain(cert)
      ..usePrivateKey(key, password: results['password']);
  } on FileSystemException catch (e) {
    print('Unable to open certificate file.');
    print('${e.message}: ${e.path}');
    exit(2);
  } catch (e) {
    print('Unexpected error: $e');
    exit(3);
  }

  return context;
}

void printHelp() {
  print('''Usage: dart bin/main.dart <options>
  
  Options:
  --cert or -c (Required)
    Path to the security certificate chain (preferrably in PEM format).
  --key or -k (Required)
    Path to the key file for the certificate chain (preferrably in PEM format).
  --password or -p
    Password required for security key. Omit for no (null) password. Pass the
    parameter but do not include any password for an empty password string.''');
}

class SimpleServer {
  HttpServer _svr;

  SecurityContext context;

  SimpleServer(this.context);

  Future start() async {
    _svr = await HttpServer.bindSecure(InternetAddress.ANY_IP_V4, 443, context);
    _svr.listen(handleRequest);
  }

  static Future handleRequest(HttpRequest req) async {
    print('${new DateTime.now()}: [${req.connectionInfo.remoteAddress.address}] - ${req.requestedUri}');

    var path = req.uri.path;
    if (path.endsWith('favicon.ico')) {
      req.response.statusCode = HttpStatus.NOT_FOUND;
      req.response.writeln('not found');
      return req.response.close();
    }

    if (path == '/ws') return handleWebsocket(req);

    req.response..headers.contentType = ContentType.HTML
        ..writeln(indexPage);
    return req.response.close();
  }

  static Future handleWebsocket(HttpRequest req) async {
    if (!WebSocketTransformer.isUpgradeRequest(req)) {
      print('Invalid Websocket request.');
      req.response
          ..statusCode = HttpStatus.BAD_REQUEST
          ..writeln('invalid request');
      return req.response.close();
    }

    var ws = await WebSocketTransformer.upgrade(req);
    ws.listen((String data) {
      print('${new DateTime.now()}: [${req.connectionInfo.remoteAddress.address}] - Websocket: $data');
      ws.add('Pong!');
    },
        onDone: () {
          print('${new DateTime.now()}: [${req.connectionInfo.remoteAddress.address}] - Websocket closed');
      ws?.close();
    });

    return req.response.close();
  }

  static void wsMsg(String data) {
    print('Websocket received: $data');
  }
}
