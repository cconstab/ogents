import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:at_cli_commons/at_cli_commons.dart';
import 'package:at_client/at_client.dart';
import 'package:at_utils/at_logger.dart';
import 'package:logging/logging.dart';
import 'package:chalkdart/chalk.dart';
import 'package:args/args.dart';
import 'package:uuid/uuid.dart';

import 'file_processor.dart';
import 'llm_client.dart';

/// Main entry point for the file agent
Future<void> runFileAgent(List<String> arguments) async {
  final agent = FileAgent();
  await agent.run(arguments);
}

/// AI Agent with atSign that processes file notifications and summarizes files using LLM
class FileAgent {
  static const String defaultNameSpace = 'ogents';
  static const String fileShareKey = 'file_share';
  static const String summaryKey = 'file_summary';

  late AtClient atClient;
  late String currentAtSign;
  late String llmAtSign;
  late String nameSpace;
  late FileProcessor fileProcessor;
  late LLMClient llmClient;

  final logger = AtSignLogger('FileAgent');

  Future<void> run(List<String> args) async {
    // Setup logging
    AtSignLogger.defaultLoggingHandler = AtSignLogger.stdErrLoggingHandler;
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

    // Extract configuration
    currentAtSign = parsedArgs['atsign'];
    llmAtSign = parsedArgs['llm-atsign'];
    nameSpace = '${parsedArgs['namespace']}.${defaultNameSpace}';

    print(chalk.blue('Starting ogents file agent...'));
    print(chalk.blue('Agent atSign: $currentAtSign'));
    print(chalk.blue('LLM atSign: $llmAtSign'));
    print(chalk.blue('Namespace: $nameSpace'));

    // Initialize atClient
    await _initializeAtClient(parsedArgs);

    // Initialize processors
    fileProcessor = FileProcessor(
      atClient: atClient,
      nameSpace: nameSpace,
      downloadPath: parsedArgs['download-path'] ?? './downloads',
    );

    llmClient = LLMClient(
      atClient: atClient,
      nameSpace: nameSpace,
      llmAtSign: llmAtSign,
    );

    // Start listening for file notifications
    await _startFileNotificationListener();

    print(
      chalk.green(
        '✅ File agent is now running and listening for file notifications...',
      ),
    );
    print(
      chalk.yellow(
        'Send files to $currentAtSign using the key pattern: "$fileShareKey"',
      ),
    );
    print(chalk.gray('Press Ctrl+C to stop'));

    // Keep the program running
    while (true) {
      await Future.delayed(Duration(seconds: 1));
    }
  }

  ArgParser _createArgumentParser() {
    final parser = CLIBase.argsParser;

    parser.addOption(
      'llm-atsign',
      abbr: 'l',
      mandatory: true,
      help: 'atSign of the LLM service to send files for summarization',
    );

    parser.addOption(
      'download-path',
      abbr: 'p', // Changed from 'd' to 'p' to avoid conflict with root-domain
      help: 'Directory to download files to',
      defaultsTo: './downloads',
    );

    return parser;
  }

  Future<void> _initializeAtClient(ArgResults parsedArgs) async {
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
              progName: 'ogents',
              uniqueID: Uuid().v4(),
            ),
        verbose: parsedArgs['verbose'],
        syncDisabled: parsedArgs['never-sync'],
        maxConnectAttempts: int.parse(parsedArgs['max-connect-attempts']),
      );

      await cli.init();
      atClient = cli.atClient;
      currentAtSign = cli.atSign;

      print(chalk.green('✅ Connected to atServer'));
    } catch (e) {
      print(chalk.red('❌ Failed to initialize atClient: $e'));
      exit(1);
    }
  }

  Future<void> _startFileNotificationListener() async {
    // Subscribe to file share notifications
    final regex = '$fileShareKey\\.$nameSpace@';

    print(chalk.blue('🔍 Listening for notifications matching: $regex'));

    atClient.notificationService
        .subscribe(regex: regex, shouldDecrypt: true)
        .listen(
          _handleFileNotification,
          onError: (error) {
            logger.severe('Notification error: $error');
            print(chalk.red('❌ Notification error: $error'));
          },
          onDone: () {
            logger.info('Notification listener stopped');
            print(chalk.yellow('⚠️ Notification listener stopped'));
          },
        );
  }

  Future<void> _handleFileNotification(AtNotification notification) async {
    try {
      print(
        chalk.cyan('📨 Received file notification from ${notification.from}'),
      );
      logger.info(
        'File notification received from ${notification.from}, ID: ${notification.id}',
      );

      // Parse the file information from notification value
      final fileInfo = _parseFileInfo(notification.value);
      if (fileInfo == null) {
        print(chalk.red('❌ Invalid file information in notification'));
        return;
      }

      print(
        chalk.blue(
          '📄 File: ${fileInfo['filename']}, Size: ${fileInfo['size']} bytes',
        ),
      );

      // Download the file
      print(chalk.yellow('⬇️ Downloading file...'));
      final downloadedFile = await fileProcessor.downloadFile(
        notification.from,
        fileInfo,
      );

      if (downloadedFile == null) {
        print(chalk.red('❌ Failed to download file'));
        return;
      }

      print(chalk.green('✅ File downloaded: ${downloadedFile.path}'));

      // Read the original file data for web frontend
      final originalFileData = await downloadedFile.readAsBytes();

      // Process the file and get summary
      print(chalk.yellow('🤖 Sending file to LLM for summarization...'));
      final summary = await _summarizeFile(downloadedFile, notification.from);

      if (summary != null) {
        print(chalk.green('✅ File summarized successfully'));
        print(
          chalk.gray(
            'Summary: ${summary.substring(0, summary.length > 100 ? 100 : summary.length)}...',
          ),
        );

        // Send summary back to sender
        await _sendSummaryNotification(
          notification.from,
          summary,
          fileInfo['filename'],
        );
        print(chalk.green('✅ Summary sent back to ${notification.from}'));

        // Send data to web frontend for dashboard display
        await _sendWebFrontendNotification(
          fileInfo['filename'],
          summary,
          originalFileData,
        );
        print(chalk.green('✅ Data sent to web frontend'));
      } else {
        print(chalk.red('❌ Failed to get summary from LLM'));
      }
    } catch (e, stackTrace) {
      logger.severe('Error handling file notification: $e', e, stackTrace);
      print(chalk.red('❌ Error processing file notification: $e'));
    }
  }

  Map<String, dynamic>? _parseFileInfo(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      logger.warning('Failed to parse file info JSON: $e');
      return null;
    }
  }

  Future<String?> _summarizeFile(File file, String fromAtSign) async {
    try {
      // Read file content
      final content = await fileProcessor.extractTextContent(file);
      if (content.isEmpty) {
        return 'Unable to extract text content from this file type.';
      }

      // Check if content was extracted via OCR
      if (content.contains('**PDF Text Content (Extracted with') ||
          content.contains('**Image File Processed**') ||
          content.startsWith('📄 **PDF Text Content')) {
        // For multi-page PDFs, send to LLM for summarization
        if (content.contains('Pages') && content.contains('--- Page ')) {
          final prompt =
              'Please provide a comprehensive summary of this multi-page PDF content. Include key information from all pages:\n\n$content';
          return await llmClient.sendToLLM(prompt, fromAtSign);
        }

        // For single-page or image OCR content, return directly
        return content;
      }

      // For other content types, send to LLM for summarization
      final prompt =
          'Please provide a concise summary of the following file content:\n\n$content';
      return await llmClient.sendToLLM(prompt, fromAtSign);
    } catch (e) {
      logger.severe('Error summarizing file: $e');
      return null;
    }
  }

  Future<void> _sendSummaryNotification(
    String toAtSign,
    String summary,
    String filename,
  ) async {
    try {
      final summaryData = {
        'filename': filename,
        'summary': summary,
        'timestamp': DateTime.now().toIso8601String(),
        'agent': currentAtSign,
      };

      final key = AtKey()
        ..key = summaryKey
        ..sharedBy = currentAtSign
        ..sharedWith = toAtSign
        ..namespace = nameSpace
        ..metadata = (Metadata()
          ..isEncrypted = true
          ..isPublic = false
          ..namespaceAware = true);

      final result = await atClient.notificationService.notify(
        NotificationParams.forUpdate(key, value: jsonEncode(summaryData)),
        checkForFinalDeliveryStatus: false,
      );

      if (result.atClientException != null) {
        throw result.atClientException!;
      }

      logger.info('Summary notification sent to $toAtSign');
    } catch (e) {
      logger.severe('Failed to send summary notification: $e');
      rethrow;
    }
  }

  Future<void> _sendWebFrontendNotification(
    String filename,
    String summary,
    Uint8List originalFileData,
  ) async {
    try {
      // Send notification to web frontend for dashboard display
      final webData = {
        'type': 'processed_file',
        'filename': filename,
        'summary': summary,
        'fileData': base64Encode(originalFileData),
        'processedAt': DateTime.now().toIso8601String(),
        'agent': currentAtSign,
        'fileSize': originalFileData.length,
      };

      final webKey = AtKey()
        ..key = 'web_frontend_data'
        ..sharedBy = currentAtSign
        ..sharedWith =
            currentAtSign // Send to self for web frontend
        ..namespace = nameSpace
        ..metadata = (Metadata()
          ..isEncrypted = false
          ..isPublic = false
          ..namespaceAware = true);

      final webResult = await atClient.notificationService.notify(
        NotificationParams.forUpdate(webKey, value: jsonEncode(webData)),
        checkForFinalDeliveryStatus: false,
      );

      if (webResult.atClientException != null) {
        throw webResult.atClientException!;
      }

      logger.info('Web frontend notification sent for file: $filename');
      print(chalk.cyan('🔔 Web frontend notification sent:'));
      print(chalk.gray('📨 To: $currentAtSign'));
      print(chalk.gray('🔑 Key: ${webKey.toString()}'));
      print(chalk.gray('📄 Data size: ${jsonEncode(webData).length} chars'));
    } catch (e) {
      logger.severe('Failed to send web frontend notification: $e');
      // Don't rethrow as this is not critical for the main flow
    }
  }
}
