import 'dart:async';
import 'dart:io';

import 'package:ogents/ogents.dart' as ogents;
import 'package:at_cli_commons/at_cli_commons.dart';
import 'package:at_client/at_client.dart';
import 'package:at_utils/at_logger.dart';
import 'package:logging/logging.dart';
import 'package:chalkdart/chalk.dart';
import 'package:args/args.dart';

void main(List<String> arguments) async {
  await runZonedGuarded(() async {
    await ogents.runFileAgent(arguments);
  }, (error, stackTrace) {
    stderr.writeln('Uncaught error: $error');
    stderr.writeln(stackTrace.toString());
    exit(1);
  });
}
