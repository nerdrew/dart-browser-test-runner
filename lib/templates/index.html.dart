import 'package:mustache4dart/mustache4dart.dart' as mustache;

compile() {
  return mustache.compile("""
<!DOCTYPE html>
<html>
  <head><title>{{title}}</title></head>
  <body>
    <div id="status"></div>
    <ul id="tests">
      <li><a href="testHtml?test=all">All Tests</a></li>
      {{#tests}}<li><a href="testHtml?test={{file}}">{{file}}</a></li>{{/tests}}
    </ul>
    <script type="application/dart" src="ws_client.dart"></script>
    <script type="text/javascript" src="packages/browser/dart.js"></script>
  </body>
</html>
""");
}
