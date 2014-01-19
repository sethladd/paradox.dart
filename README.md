# Paradox

## Workign with HttpRequests, even when offline

This library is an attempt to help you write offline-first apps. It queues
up HttpRequests and retries them until successful. Your requests are
retried until you are online and the request is a success.

## Usage

```dart
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
```

## Status

Very much alpha. Feedback welcome!

See LICENSE.
