library browser_test_runner_cli;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Runner {
  Runner(arguments) {
    var port, file;

    switch(arguments.length) {
      case 0:
        file = 'all';
        port = 9876;
        break;
      case 1:
        file = arguments[0];
        port = 9876;
        break;
      case 2:
        file = arguments[0];
        port = arguments[1];
        break;
    }

    runTest('http://127.0.0.1:$port/runTest?test=$file');
  }

  void runTest(url) {
    http.read(url).then((body) {
      print(body);
    });
  }
}
