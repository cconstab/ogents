import 'dart:async';
import 'dart:io';

import 'package:ogents/ogents.dart' as ogents;

void main(List<String> arguments) async {
  await runZonedGuarded(
    () async {
      await ogents.runFileAgent(arguments);
    },
    (error, stackTrace) {
      stderr.writeln('Uncaught error: $error');
      stderr.writeln(stackTrace.toString());
      exit(1);
    },
  );
}
