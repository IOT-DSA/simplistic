const indexPage = '''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Test page</title>
</head>
<body>
  <H1>Reached a Page.</H1>
<script>
var intId = -1;
var scheme = (window.location.protocol == 'https:' ? 'wss:' : 'ws:');
var host = window.location.host;
var url = scheme + '//' + host + '/ws';
console.log(url);

function sendPing(socket) {
  socket.send("Ping?");
}

function wsOpen(event) {
  console.log("connection established. Ping?");
  ws.send("Ping?");
  intId = window.setInterval(sendPing, 30 * 1000, ws);
}

var ws = new WebSocket(url);
ws.onmessage = function (event) {
  console.log(event.data);
};
ws.onopen = wsOpen;

</script>
</body>
</html>
''';
