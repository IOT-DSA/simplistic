import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'package:simplistic/simplistic.dart';

Future main(List<String> args) async {
  var context = parseArgs(args);
  var server = new SimpleServer(context);

  server.start();
}

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


  var cert = results['cert'];
  var key = results['key'];

  if (cert == null || key == null) {
    print('Missing required aregument.');
    printHelp();
    exit(1);
  }

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
