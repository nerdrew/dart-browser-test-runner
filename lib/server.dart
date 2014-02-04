library browser_test_runner_server;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:mirrors';
import 'package:route/server.dart' show Router;
import 'package:path/path.dart' as path;
import 'templates/index.html.dart' as indexTemplate;
import 'templates/test.html.dart' as htmlTemplate;
import 'templates/test.dart.dart' as dartTemplate;

class Server {

  Function _testDart = dartTemplate.compile();
  Function _testHtml = htmlTemplate.compile();
  Function _index = indexTemplate.compile();
  var _rootDir;
  Future _futureServer;
  WebSocket _webSocket;
  Queue<HttpResponse> _waitingRunnerResponses;
  static final TEST_OUTPUT_DONE = new RegExp(r'^((unittest-suite-success)|(\d+ PASSED, \d+ FAILED, \d+ ERRORS))$');

  factory Server.fromCLI(List<String> arguments) {
    String dir;
    int port;

    if (arguments.length == 0) {
      dir = Directory.current.path;
      port = 9876;
    } else if (arguments.length == 1) {
      dir = arguments[0];
      port = 9876;
    } else if (arguments.length == 2) {
      dir = arguments[0];
      port = int.parse(arguments[1], onError: (badPort) {
        print("'$badPort' is not an integer. Aborting.");
      });
    }

    if (port == null) {
      print("Invalid arguments. USAGE: dart bin/server.dart [<path-to-test-dir> [<port>]]");
      return;
    }

    new Server(dir, port);
  }

  Server(String baseDir, int port) {
    var dir = new Directory(baseDir);

    _checkDirectoryExists(dir);
    _rootDir = path.relative(path.normalize(dir.path));

    _waitingRunnerResponses = new Queue();
    _setupHttpServer(port);
  }

  void stop() {
    _futureServer.then((server) {
      server.close(force: true);
    });
  }

  void _setupHttpServer(port) {
    runZoned(() {
      _futureServer = HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port).then((server) {
        print('Test runner for "$_rootDir" listening on: http://${server.address.address}:$port');

        var router = new Router(server);

        router.serve('/').listen(_sendTestList);
        router.serve('/runTest').listen(_runTestInBrowser);
        router.serve('/testHtml').listen(_sendTestHtml);
        router.serve('/testDart').listen(_sendTestDart);
        router.serve('/ws_client.dart').listen(_sendWsClient);
        router.serve('/ws').transform(new WebSocketTransformer()).listen(_handleWebSocket);
        router.defaultStream.listen(_sendFile);

        return server;
      });
    }, onError: (e, stackTrace) => print('Bam! $e $stackTrace'));
  }

  void _checkDirectoryExists(dir) {
    dir.exists().then((bool exists) {
      if (!exists) {
        print('$dir does not exist!');
        exit(1);
      }
    });
  }

  void _sendNotFound(response) {
    response.statusCode = HttpStatus.NOT_FOUND;
    response.close();
  }

  List<String> _listFiles(String dirStr) {
    Directory dir = new Directory(dirStr);
    List<FileSystemEntity> entries = dir.listSync();
    return entries.where((FileSystemEntity entry) {
      return (entry is File && entry.path.endsWith('test.dart'));
    }).map((File file) {
      return path.basename(file.path);
    }).toList();
  }

  List<Map<String, String>> _mapTests(List<String> files) {
    return files.map((String file) {
      String name = file.replaceAll('.dart', '');
      return {'file': file, 'name': name};
    }).toList();
  }

  void _sendTestList(request) {
    request.response.write(_index({'tests': _mapTests(_listFiles(_rootDir)), 'title': 'Select a test to run'}));
    request.response.close();
  }

  void _runTestInBrowser(request) {
    var file = _parseTestRunnerFilename(request.uri.queryParameters['test']);

    if (_webSocket == null || _webSocket.closeCode != null) {
      request.response.write('No browser runner client connected!');
      request.response.close();
    } else {
      file.exists().then((exist) {
        if (exist || file.path == 'all') {
          request.response.write('Running tests for: "$file"');
          _webSocket.add(JSON.encode({'test': path.basename(file.path)}));
          _waitingRunnerResponses.add(request.response);
        } else {
          request.response.statusCode = HttpStatus.NOT_FOUND;
          request.response.write('$file does not exist');
          request.response.close();
        }
      });
    }
  }

  String _parseTestRunnerFilename(input) {
    var pathname = path.split(path.relative(path.normalize(input.toString())));
    if (pathname[0] != 'all' && pathname[0] != _rootDir) pathname.insert(0, _rootDir);
    return new File(path.joinAll(pathname));
  }

  void _sendOutputToRunner(string) {
    if (_waitingRunnerResponses.isEmpty) return;

    _waitingRunnerResponses.first.write("$string\n");
    if (TEST_OUTPUT_DONE.hasMatch(string)) _waitingRunnerResponses.removeFirst().close();
  }

  void _sendTestHtml(request) {
    String test = request.uri.queryParameters['test'];
    request.response.write(_testHtml({'file': test}));
    request.response.close();
  }

  void _sendTestDart(request) {
    List<String> files = request.uri.queryParameters['test'].split(',');
    if (files[0] == 'all') files = _listFiles(_rootDir);
    request.response.write(_testDart({'tests': _mapTests(files)}));
    request.response.close();
  }

  void _sendFile(request) {
    final File file = new File('${_rootDir}${request.uri.path}');
    file.exists().then((exists) {
      if (exists) file.openRead().pipe(request.response).catchError((e) { });
      else _sendNotFound(request.response);
    });
  }

  void _sendWsClient(request) {
    final File file = new File('${_rootDir}/packages/browser_test_runner/client.dart');
    file.exists().then((exists) {
      if (exists) file.openRead().pipe(request.response).catchError((e) { });
      else _sendNotFound(request.response);
    });
  }

  void _handleWebSocket(WebSocket ws) {
    _webSocket = ws;

    _webSocket.listen((data) {
      print(data);
      _sendOutputToRunner(data);
    }, onError: (error) {
      print('Bad WebSocket request: $error');
    });
  }
}
