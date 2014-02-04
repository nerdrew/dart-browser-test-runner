library browser_test_runner_client;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

class Client {
  static const Duration RECONNECT_DELAY = const Duration(seconds: 2);

  bool _connectPending = false;
  WebSocket _webSocket;
  DivElement _statusElement = querySelector("#status");
  String _wsUrl = 'ws://${Uri.base.host}:${Uri.base.port}/ws';
  String _logUrl = 'http://${Uri.base.host}:${Uri.base.port}/log';
  StreamController _logger;
  StreamSubscription _loggerSubscription;
  ZoneSpecification _zoneSpec;

  Client() {
    _setupLogger();
    _connectWs();
  }

  void _connectWs() {
    _connectPending = false;
    _webSocket = new WebSocket(_wsUrl);
    _webSocket.onOpen.first.then((_) {
      _onWsConnected();
      _webSocket.onClose.first.then((_) {
        _setStatus("Connection disconnected to ${_webSocket.url}");
        _onWsDisconnected();
      });
    });
    _webSocket.onError.first.then((_) {
      _setStatus("Failed to connect to ${_webSocket.url}. "
            "Please run bin/server.dart and try again.");
      _onWsDisconnected();
    });
  }

  void _onWsConnected() {
    print('Client connected');
    _clearStatus();
    _webSocket.onMessage.listen((e) {
      _onWsMessage(e.data);
    });
    _loggerSubscription.resume();
  }

  void _onWsDisconnected() {
    if (_connectPending) return;
    _connectPending = true;
    _loggerSubscription.cancel();
    _setStatus('Disconnected - start \'bin/server.dart\' to continue');
    new Timer(RECONNECT_DELAY, _connectWs);
  }

  void _setStatus(String status) {
    print(status);
    _statusElement.innerHtml = status;
  }

  void _clearStatus() {
    _statusElement.innerHtml = '';
  }

  void _onWsMessage(data) {
    var json = JSON.decode(data);
    if (json is Map && json['test'] != null) {
      _webSocket.send('Running test: ${json['test']}');
      window.location.assign('/testHtml?test=${json['test']}');
    }
  }

  void runTests(Function tests) {
    runZoned(() {
      tests();
    }, zoneSpecification: _zoneSpec);
  }

  void _setupLogger() {
    _logger = new StreamController.broadcast();

    _loggerSubscription = _logger.stream.listen((string) {
      _webSocket.send(string);
    });

    _loggerSubscription.pause();

    _zoneSpec = new ZoneSpecification(print: (Zone self, ZoneDelegate parent, Zone origin, String line) {
      _logger.add(line);
      parent.print(origin, line);
    });
  }
}

void main() {
  var client = new Client();
}
