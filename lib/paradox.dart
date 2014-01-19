library paradox;

import 'dart:html';
import 'dart:async';
import 'package:lawndart/lawndart.dart';
import 'package:uuid/uuid.dart';

bool _isOnline;
bool get isOnline => _isOnline;

Store _store;

Uuid _uuid = new Uuid();

class Response {
  final String id;
  final bool sent;
  final int statusCode;
  final String statusMessage;

  Response(this.id, this.sent, this.statusCode, this.statusMessage);

  bool get success => statusCode >= 200 && statusCode < 300;
}

Future<SendHttpRequest> init() {
  _isOnline = window.navigator.onLine;
  window.onOnline.listen((_) {
    _isOnline = true;
    _sendQueuedRequest();
  });
  window.onOffline.listen((_) => _isOnline = false);
  _store = new Store('paradox', 'queued_messages');

  new Timer(const Duration(seconds: 10), _sendQueuedRequest);

  return _store.open().then((_) => _httpRequest);
}

typedef Future SendHttpRequest(String url, {String method, bool withCredentials,
    String responseType, String mimeType, Map<String, String> requestHeaders,
    sendData});

Future<Response> _httpRequest(String url, {String method, bool withCredentials,
  String responseType, String mimeType, Map<String, String> requestHeaders,
  sendData}) {

  String id = _uuid.v1();

  var req = new _Request(id)
    ..url = url
    ..method = method
    ..withCredentials = withCredentials
    ..responseType = responseType
    ..mimeType = mimeType
    ..requestHeaders = requestHeaders
    ..sendData = sendData;

  return _store.save(req.toMap(), req.id)
      .then((_) => _attemptSendAndCleanup(req));

}

Future<Response> _attemptSend(_Request req) {
  if (_isOnline) {
    return HttpRequest.request(req.url, method: req.method,
        withCredentials: req.withCredentials,
        responseType: req.responseType, mimeType: req.mimeType,
        requestHeaders: req.requestHeaders, sendData: req.sendData).then((r) {
          return new Response(req.id, true, r.status, r.statusText);
        })
        .catchError((ProgressEvent e) {
          // TODO handle network errors vs server errors
          return new Response(req.id, true, 500, e.toString());
        });
  } else {
    return new Future.value(new Response(req.id, false, null, null));
  }
}

Future<Response> _attemptSendAndCleanup(_Request req) {
  return _attemptSend(req)
      .then((resp) {
        if (resp.sent && resp.success) {
          return _store.removeByKey(req.id).then((_) => resp);
        } else {
          req.bumpNextAttemptAt();
          print('Failed to send req, trying again at ${req.nextAttemptAt}');
          return _store.save(req.toMap(), req.id).then((_) => resp);
        }
      });
}

_sendQueuedRequest() {
  if (!_isOnline) return;
  _store.keys().listen((key) {
    _store.getByKey(key)
      .then((reqAsMap) => new _Request.fromMap(reqAsMap))
      .then((req) {
        if (req.timeToSend) {
          return _attemptSendAndCleanup(req);
        }
      });
  },
  onDone: () => new Timer(const Duration(seconds: 10), _sendQueuedRequest));
}

class _Request {
  final String id;
  final DateTime createdAt;
  DateTime nextAttemptAt;
  int numRetries = 0;
  String url;
  String method;
  bool withCredentials;
  String responseType;
  String mimeType;
  Map<String, String> requestHeaders;
  dynamic sendData;

  _Request(this.id) : createdAt = new DateTime.now() {
    nextAttemptAt = createdAt.add(const Duration(seconds: 10));
  }

  _Request.fromMap(Map map)
      : id = map['id'],
        createdAt = map['createdAt'],
        nextAttemptAt = map['nextAttemptAt'],
        numRetries = map['numRetries'],
        url = map['url'],
        method = map['method'],
        withCredentials = map['withCredentials'],
        responseType = map['responseType'],
        mimeType = map['mimeType'],
        requestHeaders = map['requestHeaders'],
        sendData = map['sendData'];

  void bumpNextAttemptAt() {
    numRetries++;
    nextAttemptAt = new DateTime.now().add(new Duration(seconds: 10 * numRetries));
  }

  bool get timeToSend => new DateTime.now().isAfter(nextAttemptAt);

  Map toMap() {
    return {
      'id': id,
      'createdAt': createdAt,
      'nextAttemptAt': nextAttemptAt,
      'numRetries': numRetries,
      'url': url,
      'method': method,
      'withCredentials': withCredentials,
      'responseType': responseType,
      'mimeType': mimeType,
      'requestHeaders': requestHeaders,
      'sendData': sendData
    };
  }
}
