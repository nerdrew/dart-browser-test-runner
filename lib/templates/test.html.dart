import 'package:mustache4dart/mustache4dart.dart' as mustache;

compile() {
  return mustache.compile("""
<!DOCTYPE html> <html>
  <head><title>{{title}}</title></head>
  <body>
    <div id="status"></div>
    <a href="/">Test List</a>
    <script type="application/dart" src="testDart?test={{file}}"></script>
    <script type="text/javascript" src="packages/browser/dart.js"></script>
  </body>
</html>
""");
}
