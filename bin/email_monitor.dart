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
import 'package:enough_mail/enough_mail.dart';

/// Simple email monitoring agent that processes PDF attachments
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
  final emailDir = parsedArgs['email-dir'];
  final pollInterval = int.parse(parsedArgs['poll-interval'] ?? '60');
  final useImap = parsedArgs['imap-server'] != null;

  // Validate configuration
  if (useImap) {
    if (parsedArgs['email'] == null || parsedArgs['password'] == null) {
      print(
        chalk.red('❌ For IMAP mode, both --email and --password are required'),
      );
      exit(1);
    }
  } else {
    if (emailDir == null) {
      print(chalk.red('❌ For directory mode, --email-dir is required'));
      exit(1);
    }
  }

  print(chalk.blue('Starting Email PDF Agent...'));
  if (useImap) {
    print(chalk.blue('Mode: IMAP Email Monitoring'));
    print(chalk.blue('IMAP Server: ${parsedArgs['imap-server']}'));
    print(chalk.blue('Email: ${parsedArgs['email']}'));
  } else {
    print(chalk.blue('Mode: Directory Monitoring'));
    print(chalk.blue('Email Directory: $emailDir'));
  }
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
    emailDir: emailDir,
    atClient: atClient,
    agentAtSign: agentAtSign,
    nameSpace: nameSpace,
    pollInterval: pollInterval,
    // IMAP configuration
    imapServer: parsedArgs['imap-server'],
    imapPort: parsedArgs['imap-port'] != null
        ? int.parse(parsedArgs['imap-port'])
        : null,
    email: parsedArgs['email'],
    password: parsedArgs['password'],
    useSSL: parsedArgs['ssl'] ?? true,
    folderName: parsedArgs['folder'] ?? 'INBOX',
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
    'email-dir',
    abbr: 'e',
    help:
        'Directory to monitor for email files with PDF attachments (default: ./email_monitor)',
    defaultsTo: './email_monitor',
  );

  parser.addOption(
    'poll-interval',
    abbr: 'i',
    help: 'Directory/Email check interval in seconds (default: 60)',
    defaultsTo: '60',
  );

  // IMAP Configuration
  parser.addOption(
    'imap-server',
    help: 'IMAP server hostname (e.g., imap.gmail.com)',
  );

  parser.addOption(
    'imap-port',
    help: 'IMAP server port (default: 993 for SSL, 143 for non-SSL)',
  );

  parser.addOption('email', help: 'Email address for IMAP authentication');

  parser.addOption(
    'password',
    help: 'Password for IMAP authentication (use app passwords for Gmail)',
  );

  parser.addFlag(
    'ssl',
    help: 'Use SSL/TLS for IMAP connection (default: true)',
    defaultsTo: true,
  );

  parser.addOption(
    'folder',
    help: 'Email folder to monitor (default: INBOX)',
    defaultsTo: 'INBOX',
  );

  return parser;
}

/// Email monitoring class that watches for PDF files in a directory or IMAP inbox
class EmailMonitor {
  final String? emailDir;
  final AtClient atClient;
  final String agentAtSign;
  final String nameSpace;
  final int pollInterval;

  // IMAP configuration
  final String? imapServer;
  final int? imapPort;
  final String? email;
  final String? password;
  final bool useSSL;
  final String folderName;

  final logger = AtSignLogger('EmailMonitor');
  final Set<String> processedFiles = <String>{};
  final Set<int> processedEmailUids = <int>{};
  Timer? pollTimer;
  MailClient? mailClient;
  bool get isImapMode =>
      imapServer != null && email != null && password != null;

  EmailMonitor({
    this.emailDir,
    required this.atClient,
    required this.agentAtSign,
    required this.nameSpace,
    required this.pollInterval,
    // IMAP configuration
    this.imapServer,
    this.imapPort,
    this.email,
    this.password,
    this.useSSL = true,
    this.folderName = 'INBOX',
  });

  Future<void> start() async {
    if (isImapMode) {
      await _startImapMonitoring();
    } else {
      await _startDirectoryMonitoring();
    }
  }

  Future<void> _startDirectoryMonitoring() async {
    if (emailDir == null) {
      throw ArgumentError(
        'Email directory must be specified for directory monitoring',
      );
    }

    // Ensure directory exists
    final dir = Directory(emailDir!);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print(chalk.yellow('📁 Created monitoring directory: $emailDir'));
      print(
        chalk.gray(
          '💡 Place PDF files in this directory for automatic processing',
        ),
      );
    }

    print(chalk.yellow('🔄 Starting file monitoring loop...'));

    // Start the monitoring loop
    pollTimer = Timer.periodic(Duration(seconds: pollInterval), (timer) async {
      try {
        await _checkForNewFiles();
      } catch (e) {
        logger.severe('Error checking files: $e');
        print(chalk.red('❌ Error checking files: $e'));
      }
    });

    // Initial check
    await _checkForNewFiles();

    // Keep the program running
    print(
      chalk.green('✅ Email agent is now running and monitoring for PDFs...'),
    );
    print(chalk.gray('Place PDF files in $emailDir for automatic processing'));
    print(chalk.gray('Press Ctrl+C to stop'));

    while (true) {
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Future<void> _startImapMonitoring() async {
    if (!isImapMode) {
      throw ArgumentError('IMAP configuration incomplete');
    }

    print(chalk.yellow('🔄 Connecting to IMAP server...'));

    try {
      await _connectToImap();
      print(chalk.green('✅ Connected to IMAP server'));

      // Start the monitoring loop
      pollTimer = Timer.periodic(Duration(seconds: pollInterval), (
        timer,
      ) async {
        try {
          await _checkForNewEmails();
        } catch (e) {
          logger.severe('Error checking emails: $e');
          print(chalk.red('❌ Error checking emails: $e'));
          // Try to reconnect on error
          try {
            await _connectToImap();
          } catch (reconnectError) {
            logger.severe('Failed to reconnect: $reconnectError');
          }
        }
      });

      // Initial check
      await _checkForNewEmails();

      print(
        chalk.green('✅ Email agent is now monitoring IMAP inbox for PDFs...'),
      );
      print(chalk.gray('Monitoring ${email!} folder: $folderName'));
      print(chalk.gray('Press Ctrl+C to stop'));

      while (true) {
        await Future.delayed(Duration(seconds: 1));
      }
    } catch (e) {
      logger.severe('Failed to connect to IMAP server: $e');
      print(chalk.red('❌ Failed to connect to IMAP server: $e'));
      throw e;
    }
  }

  Future<void> _checkForNewFiles() async {
    try {
      final dir = Directory(emailDir!);
      if (!dir.existsSync()) return;

      final files = dir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.pdf'))
          .toList();

      for (final file in files) {
        final filePath = file.path;
        if (!processedFiles.contains(filePath)) {
          await _processFile(file);
          processedFiles.add(filePath);
        }
      }
    } catch (e) {
      logger.warning('Failed to check directory: $e');
      print(chalk.yellow('⚠️ Failed to check directory: $e'));
    }
  }

  Future<void> _connectToImap() async {
    // Use the fromManualSettings constructor with proper parameters
    final account = MailAccount.fromManualSettings(
      name: 'IMAP Monitor',
      email: email!,
      password: password!,
      incomingHost: imapServer!,
      incomingPort: imapPort ?? (useSSL ? 993 : 143),
      incomingSocketType: useSSL ? SocketType.ssl : SocketType.plain,
      incomingType: ServerType.imap,
      outgoingHost: imapServer!, // Using same host for simplicity
      outgoingPort: useSSL ? 465 : 587,
      outgoingSocketType: useSSL ? SocketType.ssl : SocketType.plain,
      outgoingType: ServerType.smtp,
    );

    mailClient = MailClient(account, isLogEnabled: false);
    await mailClient!.connect();
    await mailClient!.selectInbox();
  }

  Future<void> _checkForNewEmails() async {
    if (mailClient == null) return;

    try {
      // Fetch recent unread messages using the high-level API
      final messages = await mailClient!.fetchMessages(count: 20);

      for (final message in messages) {
        final uid = message.uid;
        if (uid != null &&
            !processedEmailUids.contains(uid) &&
            !message.isSeen) {
          await _processEmailMessage(message);
          processedEmailUids.add(uid);

          // Mark as read
          await mailClient!.markSeen(MessageSequence.fromMessage(message));
        }
      }
    } catch (e) {
      logger.warning('Failed to check emails: $e');
      print(chalk.yellow('⚠️ Failed to check emails: $e'));
    }
  }

  Future<void> _processEmailMessage(MimeMessage message) async {
    try {
      final subject = message.decodeSubject() ?? 'No Subject';
      final from = message.from?.isNotEmpty == true
          ? message.from!.first.email
          : 'Unknown';

      print(chalk.yellow('📧 Processing email: $subject'));
      print(chalk.gray('From: $from'));

      // Look for PDF attachments by checking all parts
      final allParts = message.allPartsFlat;

      for (final part in allParts) {
        final contentDisposition = part.getHeaderContentDisposition();
        if (contentDisposition?.disposition == ContentDisposition.attachment) {
          final filename = contentDisposition?.filename;
          if (filename != null && filename.toLowerCase().endsWith('.pdf')) {
            print(chalk.yellow('📎 Found PDF attachment: $filename'));

            final data = part.decodeContentBinary();
            if (data != null) {
              final fileSizeMB = data.length / (1024 * 1024);
              print(
                chalk.gray('File size: ${fileSizeMB.toStringAsFixed(1)}MB'),
              );

              // Check file size - atPlatform has ~10MB limit for notifications
              const maxSizeBytes = 8 * 1024 * 1024; // 8MB to be safe
              if (data.length > maxSizeBytes) {
                print(
                  chalk.red(
                    '❌ PDF attachment too large: ${fileSizeMB.toStringAsFixed(1)}MB (max: 8MB)',
                  ),
                );
                print(
                  chalk.yellow(
                    '💡 Skipping this attachment - consider smaller PDFs',
                  ),
                );
                continue;
              }

              final base64Data = base64Encode(data);
              await _sendPDFToOgents(
                base64Data,
                filename,
                'email:$from:$subject',
              );
            }
          }
        }
      }
    } catch (e) {
      logger.severe('Error processing email message: $e');
      print(chalk.red('❌ Error processing email message: $e'));
    }
  }

  Future<void> _processFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      print(
        chalk.yellow(
          '📧 Processing PDF file: $fileName (${fileSizeMB.toStringAsFixed(1)}MB)',
        ),
      );

      // Check file size - atPlatform has ~10MB limit for notifications
      const maxSizeBytes = 8 * 1024 * 1024; // 8MB to be safe
      if (fileSize > maxSizeBytes) {
        print(
          chalk.red(
            '❌ File too large: ${fileSizeMB.toStringAsFixed(1)}MB (max: 8MB)',
          ),
        );
        print(
          chalk.yellow(
            '💡 Consider using smaller PDFs or implement file chunking',
          ),
        );
        return;
      }

      // Read file and encode as base64
      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);

      await _sendPDFToOgents(base64Data, fileName, file.path);

      // Optionally move the processed file to a subfolder
      await _moveProcessedFile(file);
    } catch (e) {
      logger.severe('Error processing file ${file.path}: $e');
      print(chalk.red('❌ Error processing file ${file.path}: $e'));
    }
  }

  Future<void> _moveProcessedFile(File file) async {
    try {
      final processedDir = Directory('$emailDir/processed');
      if (!processedDir.existsSync()) {
        processedDir.createSync();
      }

      final fileName = file.path.split('/').last;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final newPath = '${processedDir.path}/${timestamp}_$fileName';

      await file.rename(newPath);
      print(chalk.gray('📦 Moved processed file to: $newPath'));
    } catch (e) {
      logger.warning('Failed to move processed file: $e');
    }
  }

  Future<void> _sendPDFToOgents(
    String base64Data,
    String filename,
    String filePath,
  ) async {
    try {
      print(chalk.yellow('📤 Sending PDF "$filename" to ogents agent...'));

      // Prepare file information
      final fileInfo = {
        'filename': filename,
        'data': base64Data,
        'timestamp': DateTime.now().toIso8601String(),
        'sender': atClient.getCurrentAtSign(),
        'source': 'email_monitor',
        'original_path': filePath,
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

      // Listen for summary response
      await _listenForSummary(filename);
    } catch (e) {
      logger.severe('Error sending PDF to ogents: $e');
      print(chalk.red('❌ Error sending PDF to ogents: $e'));
    }
  }

  Future<void> _listenForSummary(String filename) async {
    try {
      final completer = Completer<void>();
      StreamSubscription? subscription;
      Timer? timeout;

      // Subscribe to summary responses
      final regex = 'file_summary\\.$nameSpace@';

      subscription = atClient.notificationService
          .subscribe(regex: regex, shouldDecrypt: true)
          .listen((notification) {
            try {
              final summaryData =
                  jsonDecode(notification.value!) as Map<String, dynamic>;
              final summaryFilename = summaryData['filename'];

              // Check if this summary is for our file
              if (summaryFilename == filename) {
                final summary = summaryData['summary'];
                final timestamp = summaryData['timestamp'];
                final agent = summaryData['agent'];

                print(chalk.green('\n📋 Summary received for "$filename":'));
                print(chalk.blue('Agent: $agent'));
                print(chalk.blue('Time: $timestamp'));
                print(chalk.white('\n--- SUMMARY ---'));
                print(chalk.yellow(summary));
                print(chalk.white('--- END SUMMARY ---\n'));

                if (!completer.isCompleted) {
                  completer.complete();
                }
              }
            } catch (e) {
              print(chalk.red('❌ Error parsing summary response: $e'));
            }
          });

      // Set timeout
      timeout = Timer(Duration(seconds: 120), () {
        print(chalk.yellow('⏰ Timeout waiting for summary of "$filename"'));
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await completer.future;

      subscription.cancel();
      timeout.cancel();
    } catch (e) {
      logger.warning('Error listening for summary: $e');
    }
  }

  void stop() {
    pollTimer?.cancel();
    if (mailClient != null) {
      try {
        mailClient!.disconnect();
      } catch (e) {
        logger.warning('Error disconnecting from IMAP: $e');
      }
    }
    print(chalk.yellow('📧 Email monitoring stopped'));
  }
}
