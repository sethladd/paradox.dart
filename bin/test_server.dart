library test_server;

import 'dart:io';
import 'dart:async';
import 'package:http_server/http_server.dart';

main() {
  runZoned(() {
    HttpServer.bind('0.0.0.0', 8888).then((server) {
      print('Server started');
      server.transform(new HttpBodyHandler()).listen((HttpRequestBody httpBody) {
        print('Received: ${httpBody.request.method} ${httpBody.request.uri} ${httpBody.body}');
        httpBody.request.response
          ..headers.add('Access-Control-Allow-Origin', '*')
          ..statusCode = (httpBody.body['error'] != null ? 500 : 200)
          ..close();
      });
    });
  },
  onError: (e, stackTrace) => print('ERROR: $e $stackTrace'));
}