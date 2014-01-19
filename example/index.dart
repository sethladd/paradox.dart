library example;

import 'package:paradox/paradox.dart';
import 'dart:html';

main() {
  init().then((SendHttpRequest sendRequest) {
    querySelector('button').onClick.listen((e) {
      String data = 'msg=hi';
      if ((querySelector('#force-error') as InputElement).checked) {
        data += '&error=true';
      }
      sendRequest('http://localhost:8888/test',
          method: 'POST',
          requestHeaders: {'Content-Type': 'application/x-www-form-urlencoded'},
          sendData: data);
    });
  });

  Element status = querySelector('#status')
      ..text = window.navigator.onLine.toString();

  window.onOnline.listen((_) => status.text = 'online');
  window.onOffline.listen((_) => status.text = 'offline');
}