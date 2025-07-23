import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:at_cli_commons/at_cli_commons.dart';
import 'package:at_client/at_client.dart';
import 'package:at_utils/at_logger.dart';
import 'package:logging/logging.dart';
import 'package:chalkdart/chalk.dart';
import 'package:args/args.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

/// Utility to send files to the ogents file agent
void main(List<String> arguments) async {
  await runZonedGuarded(
    () async {
      await runFileSender(arguments);
    },
    (error, stackTrace) {
      stderr.writeln('Uncaught error: $error');
      stderr.writeln(stackTrace.toString());
      exit(1);
    },
  );
}

Future<void> runFileSender(List<String> args) async {
  // Setup logging
  AtSignLogger.defaultLoggingHandler = AtSignLogger.stdErrLoggingHandler;
  final logger = AtSignLogger('FileSender');
  logger.hierarchicalLoggingEnabled = true;
  logger.logger.level = Level.INFO;

  // Parse command line arguments
  final parser = _createArgumentParser();
  ArgResults parsedArgs;

  try {
    parsedArgs = parser.parse(args);
  } catch (e) {
    print('Error parsing arguments: $e');
    print(parser.usage);
    exit(1);
  }

  if (parsedArgs['help']) {
    print(parser.usage);
    exit(0);
  }

  final filePath = parsedArgs['file'];
  final fileUrl = parsedArgs['url'];
  final agentAtSign = parsedArgs['agent'];
  final nameSpace = '${parsedArgs['namespace']}.ogents';

  // Validate input - either file or URL must be provided
  if (filePath == null && fileUrl == null) {
    print(chalk.red('❌ Either --file or --url must be provided'));
    print(parser.usage);
    exit(1);
  }

  if (filePath != null && fileUrl != null) {
    print(chalk.red('❌ Provide either --file or --url, not both'));
    print(parser.usage);
    exit(1);
  }

  // Validate file exists if using local file
  File? file;
  if (filePath != null) {
    file = File(filePath);
    if (!file.existsSync()) {
      print(chalk.red('❌ File does not exist: $filePath'));
      exit(1);
    }
  }

  print(
    chalk.blue(
      'Sending ${fileUrl != null ? 'URL' : 'file'} to ogents agent...',
    ),
  );
  if (fileUrl != null) {
    print(chalk.blue('URL: $fileUrl'));
  } else {
    print(chalk.blue('File: $filePath'));
  }
  print(chalk.blue('Agent: $agentAtSign'));
  print(chalk.blue('Namespace: $nameSpace'));

  // Initialize atClient
  late AtClient atClient;
  try {
    final cli = CLIBase(
      atSign: parsedArgs['atsign'],
      atKeysFilePath: parsedArgs['key-file'],
      nameSpace: parsedArgs['namespace'],
      rootDomain: parsedArgs['root-domain'],
      homeDir: getHomeDirectory(),
      storageDir:
          parsedArgs['storage-dir'] ??
          standardAtClientStoragePath(
            baseDir: getHomeDirectory()!,
            atSign: parsedArgs['atsign'],
            progName: 'ogents_sender',
            uniqueID: Uuid().v4(),
          ),
      verbose: parsedArgs['verbose'],
      syncDisabled: parsedArgs['never-sync'],
      maxConnectAttempts: int.parse(parsedArgs['max-connect-attempts']),
    );

    await cli.init();
    atClient = cli.atClient;

    print(chalk.green('✅ Connected to atServer'));
  } catch (e) {
    print(chalk.red('❌ Failed to initialize atClient: $e'));
    exit(1);
  }

  // Send the file or URL
  try {
    if (fileUrl != null) {
      await sendUrl(atClient, fileUrl, agentAtSign, nameSpace);
    } else {
      await sendFile(atClient, file!, agentAtSign, nameSpace);
    }
    print(
      chalk.green('✅ ${fileUrl != null ? 'URL' : 'File'} sent successfully!'),
    );

    // Listen for summary response
    print(chalk.yellow('🔍 Waiting for summary response...'));
    await listenForSummary(atClient, nameSpace);

    // Exit successfully after receiving summary
    exit(0);
  } catch (e) {
    print(chalk.red('❌ Error sending ${fileUrl != null ? 'URL' : 'file'}: $e'));
    exit(1);
  }
}

ArgParser _createArgumentParser() {
  final parser = CLIBase.argsParser;

  parser.addOption(
    'file',
    abbr: 'f',
    help: 'Path to the local file to send for summarization',
  );

  parser.addOption(
    'url',
    abbr: 'u',
    help: 'URL of the file to send for summarization',
  );

  parser.addOption(
    'agent',
    abbr: 'g',
    mandatory: true,
    help: 'atSign of the ogents file agent',
  );

  return parser;
}

Future<void> sendFile(
  AtClient atClient,
  File file,
  String agentAtSign,
  String nameSpace,
) async {
  // Read file and encode as base64
  final bytes = await file.readAsBytes();
  final base64Data = base64Encode(bytes);
  final filename = path.basename(file.path);
  final fileSize = bytes.length;

  // Prepare file information
  final fileInfo = {
    'filename': filename,
    'size': fileSize,
    'data': base64Data,
    'timestamp': DateTime.now().toIso8601String(),
    'sender': atClient.getCurrentAtSign(),
  };

  // Create the notification key
  final key = AtKey()
    ..key = 'file_share'
    ..sharedBy = atClient.getCurrentAtSign()
    ..sharedWith = agentAtSign
    ..namespace = nameSpace
    ..metadata = (Metadata()
      ..isEncrypted = true
      ..isPublic = false
      ..namespaceAware = true
      ..ttl = 3600000); // 1 hour in milliseconds

  // Send the notification
  final result = await atClient.notificationService.notify(
    NotificationParams.forUpdate(key, value: jsonEncode(fileInfo)),
    checkForFinalDeliveryStatus: false,
  );

  if (result.atClientException != null) {
    throw result.atClientException!;
  }

  print(chalk.green('📤 File notification sent'));
}

Future<void> sendUrl(
  AtClient atClient,
  String url,
  String agentAtSign,
  String nameSpace,
) async {
  // Extract filename from URL or use a default
  String filename;
  try {
    final uri = Uri.parse(url);
    filename = path.basename(uri.path);
    if (filename.isEmpty || !filename.contains('.')) {
      filename = 'url_content.txt';
    }
  } catch (e) {
    filename = 'url_content.txt';
  }

  // Prepare file information with URL
  final fileInfo = {
    'filename': filename,
    'url': url,
    'timestamp': DateTime.now().toIso8601String(),
    'sender': atClient.getCurrentAtSign(),
  };

  // Create the notification key
  final key = AtKey()
    ..key = 'file_share'
    ..sharedBy = atClient.getCurrentAtSign()
    ..sharedWith = agentAtSign
    ..namespace = nameSpace
    ..metadata = (Metadata()
      ..isEncrypted = true
      ..isPublic = false
      ..namespaceAware = true
      ..ttl = 3600000); // 1 hour in milliseconds

  // Send the notification
  final result = await atClient.notificationService.notify(
    NotificationParams.forUpdate(key, value: jsonEncode(fileInfo)),
    checkForFinalDeliveryStatus: false,
  );

  if (result.atClientException != null) {
    throw result.atClientException!;
  }

  print(chalk.green('📤 URL notification sent'));
}

Future<void> listenForSummary(AtClient atClient, String nameSpace) async {
  final completer = Completer<void>();
  StreamSubscription? subscription;
  Timer? timeout;

  try {
    // Subscribe to summary responses
    final regex = 'file_summary\\.$nameSpace@';

    subscription = atClient.notificationService
        .subscribe(regex: regex, shouldDecrypt: true)
        .listen((notification) {
          try {
            final summaryData =
                jsonDecode(notification.value!) as Map<String, dynamic>;
            final filename = summaryData['filename'];
            final summary = summaryData['summary'];
            final timestamp = summaryData['timestamp'];
            final agent = summaryData['agent'];

            print(chalk.green('\\n📋 Summary received from $agent:'));
            print(chalk.blue('File: $filename'));
            print(chalk.blue('Time: $timestamp'));
            print(chalk.white('\n--- SUMMARY ---'));
            print(chalk.yellow(summary));
            print(chalk.white('--- END SUMMARY ---\n'));

            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (e) {
            print(chalk.red('❌ Error parsing summary response: $e'));
          }
        });

    // Set timeout
    timeout = Timer(Duration(seconds: 120), () {
      print(chalk.yellow('⏰ Timeout waiting for summary response'));
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    await completer.future;
  } finally {
    subscription?.cancel();
    timeout?.cancel();
  }
}
