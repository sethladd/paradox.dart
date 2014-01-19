# Paradox

## Working with HttpRequests, even when offline

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

## How it works

The library is initialized with `init()`, which configures a local database
using the [Lawndart][] library.

Send requests using `sendRequest`, which has the same interface as
`HttpRequest.request`. The request is first stored locally. Then, the
request is tried. If successful, the request is deleted from the local
storage.

If the request fails for any reason (network, server 500, gremlins),
a timer is started for a retry. The timer fires at a constant rate until
all stored requests are successfully sent.

Each request is given a time to next retry, which exponentially increases
with every request. While the internal timer fires at a constant rate,
individual requests are increasingly delayed until successful.

If the browser detects the network connection is offline, no retries will
happen. Only when the browser detects the network connection is online will
retries occur again.

Therefore, if the browser says the connection is offline, all requests
go straight to the local database and no network connectivity is attempted.
If the browser thinks it is online, all requests are tried.

Feedback on the algorithm is much appreciated.

## Browser compatibility

This library should support all modern browsers, thanks to [Lawndart][].

## Status

Very much alpha. Feedback welcome!

## Bugs and source

Please file [issues and feature requests][bugs]. You can get
the source code from [Github][source].

See LICENSE.

[lawndart]: http://pub.dartlang.org/packages/lawndart
[bugs]: https://github.com/sethladd/paradox.dart/issues
[source]: https://github.com/sethladd/paradox.dart