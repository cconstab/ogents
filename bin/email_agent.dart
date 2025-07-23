import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:at_cli_commons/at_cli_commons.dart';
import 'package:at_client/at_client.dart' hide StringBuffer;
import 'package:at_utils/at_logger.dart';
import 'package:logging/logging.dart';
import 'package:chalkdart/chalk.dart';
import 'package:args/args.dart';
import 'package:uuid/uuid.dart';

/// Email monitoring agent that processes PDF attachments
void main(List<String> arguments) async {
  await runZonedGuarded(
    () async {
      await runEmailAgent(arguments);
    },
    (error, stackTrace) {
      stderr.writeln('Uncaught error: $error');
      stderr.writeln(stackTrace.toString());
      exit(1);
    },
  );
}

Future<void> runEmailAgent(List<String> args) async {
  // Setup logging
  AtSignLogger.defaultLoggingHandler = AtSignLogger.stdErrLoggingHandler;
  final logger = AtSignLogger('EmailAgent');
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

  final agentAtSign = parsedArgs['agent'];
  final nameSpace = '${parsedArgs['namespace']}.ogents';
  final imapServer = parsedArgs['imap-server'];
  final imapPort = int.parse(parsedArgs['imap-port'] ?? '993');
  final email = parsedArgs['email'];
  final password = parsedArgs['password'];
  final pollInterval = int.parse(parsedArgs['poll-interval'] ?? '60');

  print(chalk.blue('Starting Email PDF Agent...'));
  print(chalk.blue('IMAP Server: $imapServer:$imapPort'));
  print(chalk.blue('Email: $email'));
  print(chalk.blue('Agent: $agentAtSign'));
  print(chalk.blue('Poll Interval: ${pollInterval}s'));

  // Initialize atClient for sending files to ogents
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
            progName: 'ogents_email',
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

  // Create email monitor
  final emailMonitor = EmailMonitor(
    imapServer: imapServer,
    imapPort: imapPort,
    email: email,
    password: password,
    atClient: atClient,
    agentAtSign: agentAtSign,
    nameSpace: nameSpace,
    pollInterval: pollInterval,
  );

  // Start monitoring
  print(chalk.green('📧 Starting email monitoring...'));
  await emailMonitor.start();
}

ArgParser _createArgumentParser() {
  final parser = CLIBase.argsParser;

  parser.addOption(
    'agent',
    abbr: 'g',
    mandatory: true,
    help: 'atSign of the ogents file agent to send PDFs to',
  );

  parser.addOption(
    'imap-server',
    abbr: 's',
    mandatory: true,
    help: 'IMAP server hostname (e.g., imap.gmail.com)',
  );

  parser.addOption(
    'imap-port',
    abbr: 'p',
    help: 'IMAP port (default: 993 for SSL)',
    defaultsTo: '993',
  );

  parser.addOption(
    'email',
    abbr: 'e',
    mandatory: true,
    help: 'Email address to monitor',
  );

  parser.addOption(
    'password',
    abbr: 'w',
    mandatory: true,
    help: 'Email password or app-specific password',
  );

  parser.addOption(
    'poll-interval',
    abbr: 'i',
    help: 'Email check interval in seconds (default: 60)',
    defaultsTo: '60',
  );

  return parser;
}

/// Email monitoring class that watches for PDF attachments
class EmailMonitor {
  final String imapServer;
  final int imapPort;
  final String email;
  final String password;
  final AtClient atClient;
  final String agentAtSign;
  final String nameSpace;
  final int pollInterval;

  final logger = AtSignLogger('EmailMonitor');
  final Set<String> processedMessageIds = <String>{};
  Timer? pollTimer;
  Socket? socket;
  bool isConnected = false;

  EmailMonitor({
    required this.imapServer,
    required this.imapPort,
    required this.email,
    required this.password,
    required this.atClient,
    required this.agentAtSign,
    required this.nameSpace,
    required this.pollInterval,
  });

  Future<void> start() async {
    print(chalk.yellow('🔄 Starting email monitoring loop...'));

    // Start the monitoring loop
    pollTimer = Timer.periodic(Duration(seconds: pollInterval), (timer) async {
      try {
        await _checkForNewEmails();
      } catch (e) {
        logger.severe('Error checking emails: $e');
        print(chalk.red('❌ Error checking emails: $e'));
      }
    });

    // Initial check
    await _checkForNewEmails();

    // Keep the program running
    print(
      chalk.green('✅ Email agent is now running and monitoring for PDFs...'),
    );
    print(chalk.gray('Press Ctrl+C to stop'));

    while (true) {
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Future<void> _checkForNewEmails() async {
    try {
      await _connectToIMAP();

      final unseenMessages = await _getUnseenMessages();
      if (unseenMessages.isNotEmpty) {
        print(chalk.blue('📬 Found ${unseenMessages.length} new messages'));

        for (final messageId in unseenMessages) {
          if (!processedMessageIds.contains(messageId)) {
            await _processMessage(messageId);
            processedMessageIds.add(messageId);
          }
        }
      }

      await _disconnectFromIMAP();
    } catch (e) {
      logger.warning('Failed to check emails: $e');
      print(chalk.yellow('⚠️ Failed to check emails: $e'));
      await _disconnectFromIMAP();
    }
  }

  Future<void> _connectToIMAP() async {
    if (isConnected && socket != null) return;

    try {
      // Connect to IMAP server with SSL
      socket = await SecureSocket.connect(
        imapServer,
        imapPort,
        timeout: Duration(seconds: 30),
      );

      isConnected = true;

      // Read server greeting
      await _readResponse();

      // Login
      await _sendCommand('LOGIN $email $password');

      // Select INBOX
      await _sendCommand('SELECT INBOX');
    } catch (e) {
      await _disconnectFromIMAP();
      rethrow;
    }
  }

  Future<void> _disconnectFromIMAP() async {
    try {
      if (socket != null && isConnected) {
        await _sendCommand('LOGOUT');
      }
    } catch (e) {
      // Ignore logout errors
    } finally {
      await socket?.close();
      socket = null;
      isConnected = false;
    }
  }

  Future<String> _sendCommand(String command) async {
    if (socket == null) throw Exception('Not connected to IMAP server');

    final tag = 'A${DateTime.now().millisecondsSinceEpoch}';
    final fullCommand = '$tag $command\r\n';

    socket!.write(fullCommand);

    final response = await _readResponse();

    if (!response.contains('$tag OK')) {
      throw Exception('IMAP command failed: $command. Response: $response');
    }

    return response;
  }

  Future<String> _readResponse() async {
    if (socket == null) throw Exception('Not connected to IMAP server');

    final buffer = StringBuffer();
    final completer = Completer<String>();

    socket!.listen(
      (data) {
        final text = String.fromCharCodes(data);
        buffer.write(text);

        // Check if we have a complete response
        if (text.contains('\r\n')) {
          completer.complete(buffer.toString());
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    return completer.future.timeout(Duration(seconds: 30));
  }

  Future<List<String>> _getUnseenMessages() async {
    final response = await _sendCommand('SEARCH UNSEEN');

    // Parse message IDs from SEARCH response
    final messageIds = <String>[];
    final lines = response.split('\r\n');

    for (final line in lines) {
      if (line.startsWith('* SEARCH ')) {
        final ids = line.substring(9).trim().split(' ');
        messageIds.addAll(ids.where((id) => id.isNotEmpty));
      }
    }

    return messageIds;
  }

  Future<void> _processMessage(String messageId) async {
    try {
      print(chalk.yellow('📧 Processing message $messageId...'));

      // Fetch message headers and structure
      final response = await _sendCommand(
        'FETCH $messageId (ENVELOPE BODYSTRUCTURE)',
      );

      // Check if message has attachments
      if (!response.toLowerCase().contains('application/pdf')) {
        return; // No PDF attachments
      }

      print(chalk.blue('📎 Found PDF attachment in message $messageId'));

      // Fetch the full message to extract attachments
      final fullMessage = await _sendCommand('FETCH $messageId (RFC822)');

      // Extract PDF attachments and send to ogents
      await _extractAndSendPDFs(fullMessage, messageId);
    } catch (e) {
      logger.severe('Error processing message $messageId: $e');
      print(chalk.red('❌ Error processing message $messageId: $e'));
    }
  }

  Future<void> _extractAndSendPDFs(
    String emailContent,
    String messageId,
  ) async {
    try {
      // Simple email parsing - in production, use a proper email library
      final lines = emailContent.split('\r\n');
      bool inAttachment = false;
      String? attachmentName;
      final attachmentData = StringBuffer();

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Look for PDF attachment headers
        if (line.toLowerCase().contains('content-type: application/pdf')) {
          inAttachment = true;
          // Look for filename in next few lines
          for (int j = i; j < i + 5 && j < lines.length; j++) {
            if (lines[j].toLowerCase().contains('filename=')) {
              final match = RegExp(
                r'filename[*]?=["'
                "'"
                ']*([^"'
                "'"
                ';\r\n]+)',
              ).firstMatch(lines[j]);
              if (match != null) {
                attachmentName = match.group(1)!;
                break;
              }
            }
          }
        }

        // Look for base64 encoded data
        if (inAttachment && line.trim().isEmpty) {
          // Start collecting base64 data from next line
          for (int j = i + 1; j < lines.length; j++) {
            final dataLine = lines[j].trim();
            if (dataLine.isEmpty || dataLine.startsWith('--')) {
              break; // End of attachment
            }
            // Simple base64 detection
            if (RegExp(r'^[A-Za-z0-9+/]+=*$').hasMatch(dataLine)) {
              attachmentData.write(dataLine);
            }
          }
          break;
        }
      }

      if (attachmentData.toString().isNotEmpty && attachmentName != null) {
        await _sendPDFToOgents(
          attachmentData.toString(),
          attachmentName,
          messageId,
        );
      }
    } catch (e) {
      logger.severe('Error extracting PDFs: $e');
      print(chalk.red('❌ Error extracting PDFs: $e'));
    }
  }

  Future<void> _sendPDFToOgents(
    String base64Data,
    String filename,
    String messageId,
  ) async {
    try {
      print(chalk.yellow('📤 Sending PDF "$filename" to ogents agent...'));

      // Prepare file information
      final fileInfo = {
        'filename': filename,
        'data': base64Data,
        'timestamp': DateTime.now().toIso8601String(),
        'sender': atClient.getCurrentAtSign(),
        'source': 'email',
        'email_message_id': messageId,
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

      print(chalk.green('✅ PDF "$filename" sent to ogents agent successfully'));
    } catch (e) {
      logger.severe('Error sending PDF to ogents: $e');
      print(chalk.red('❌ Error sending PDF to ogents: $e'));
    }
  }

  void stop() {
    pollTimer?.cancel();
    _disconnectFromIMAP();
    print(chalk.yellow('📧 Email monitoring stopped'));
  }
}
