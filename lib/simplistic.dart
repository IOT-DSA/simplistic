import 'dart:async';
import 'dart:io';

import 'pages.dart';

void log(String address, String msg) {
  var now = new DateTime.now();
  print('$now: [$address] - $msg');
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
    log(req.connectionInfo.remoteAddress.address, req.requestedUri.toString());

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
    var conn = new SimpleConn(ws, req.connectionInfo);

    return req.response.close();
  }
}

class SimpleConn {
  final WebSocket ws;
  final HttpConnectionInfo info;
  bool isSet = false;
  Timer keepAlive;

  SimpleConn(this.ws, this.info) {
    ws.listen(handleData, onDone: closeWs);
  }

  void handleData(String data) {
    log(info.remoteAddress.address, 'Websocket: $data');

    switch (data) {
      case 'Ping?':
        ws.add('Pong!');
        break;
      default:
        ws.add(data); // Echo back any non-ping data
    }

    if (!isSet) {
      isSet = true;
      new Future.delayed(const Duration(seconds: 5), _setTimer);
    }
  }

  void _setTimer() {
    if (keepAlive != null) return;
    keepAlive = new Timer.periodic(const Duration(seconds: 10), (_) => ws.add('Ping?'));
  }

  void closeWs() {
    log(info.remoteAddress.address, 'Websocket closed');
    ws?.close();
    keepAlive.cancel();
  }
}
