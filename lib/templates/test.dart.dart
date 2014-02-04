import 'package:mustache4dart/mustache4dart.dart' as mustache;

compile() {
  return mustache.compile(r"""
import '../ws_client.dart' as browserTestRunnerWSClient;

{{#tests}}
import '{{file}}' as {{name}};
{{/tests}}

main(){
  var client = new browserTestRunnerWSClient.Client();
  client.runTests(() {
    {{#tests}}{{name}}.main();{{/tests}}
  });
}
""");
}
