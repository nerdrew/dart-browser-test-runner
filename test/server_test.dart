library browser_test_runner_server_test;

import 'package:unittest/unittest.dart';
import 'package:http/http.dart' as http;

import 'package:browser_test_runner/server.dart';

main() {
  var server;

  setUp(() {
    server = new Server('example', 9999);
  });

  tearDown(() {
    server.stop();
  });

  test('/ => sends list of test files', () {
    Future testRead = http.read('http://127.0.0.1:9999/');

    testRead.then((body) {
      expect(body, equals('''<!DOCTYPE html>
<html>
  <head><title>Select a test to run</title></head>
  <body>
    <div id="status"></div>
    <ul id="tests">
      <li><a href="testHtml?test=foo_test.dart">foo_test.dart</a></li>
    </ul>
    <script type="application/dart" src="ws_client.dart"></script>
    <script type="text/javascript" src="packages/browser/dart.js"></script>
  </body>
</html>
'''));
    });
    expect(testRead, completes);
  });
}
