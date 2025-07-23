import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_cli_commons/at_cli_commons.dart';
import 'package:at_client/at_client.dart' hide StringBuffer, Response;
import 'package:at_utils/at_logger.dart';
import 'package:args/args.dart';
import 'package:chalkdart/chalk.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Web frontend for ogents that displays file processing results
void main(List<String> arguments) async {
  await runZonedGuarded(
    () async {
      await runWebFrontend(arguments);
    },
    (error, stackTrace) {
      stderr.writeln('Uncaught error: $error');
      stderr.writeln(stackTrace.toString());
      exit(1);
    },
  );
}

Future<void> runWebFrontend(List<String> args) async {
  // Setup logging
  AtSignLogger.defaultLoggingHandler = AtSignLogger.stdErrLoggingHandler;
  final logger = AtSignLogger('WebFrontend');
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

  final port = int.parse(parsedArgs['port'] ?? '8090');
  final nameSpace = '${parsedArgs['namespace']}.ogents';

  print(chalk.blue('Starting ogents Web Frontend...'));
  print(chalk.blue('Port: $port'));
  print(chalk.blue('atSign: ${parsedArgs['atsign']}'));
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
            progName: 'ogents_web',
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

  // Create web server
  final webServer = WebServer(
    atClient: atClient,
    nameSpace: nameSpace,
    port: port,
  );

  // Start server
  await webServer.start();
}

ArgParser _createArgumentParser() {
  final parser = CLIBase.argsParser;

  parser.addOption(
    'port',
    abbr: 'p',
    help: 'Port to run the web server on (default: 8090)',
    defaultsTo: '8090',
  );

  return parser;
}

/// Web server that serves the frontend and handles WebSocket connections
class WebServer {
  final AtClient atClient;
  final String nameSpace;
  final int port;

  final logger = AtSignLogger('WebServer');
  final List<ProcessedFile> processedFiles = [];
  final Set<WebSocketChannel> webSocketClients = {};

  WebServer({
    required this.atClient,
    required this.nameSpace,
    required this.port,
  });

  Future<void> start() async {
    // Setup notification listener
    await _setupNotificationListener();

    // Setup router
    final router = Router();

    // API endpoints
    router.get('/api/files', _handleGetFiles);
    router.get('/api/files/<fileId>/download', _handleDownloadFile);
    router.get('/api/files/<fileId>', _handleGetFile);

    // WebSocket endpoint
    router.get(
      '/ws',
      webSocketHandler((WebSocketChannel webSocket) {
        webSocketClients.add(webSocket);
        print(chalk.blue('📱 New WebSocket client connected'));

        webSocket.stream.listen(
          (message) {
            // Handle incoming WebSocket messages if needed
          },
          onDone: () {
            webSocketClients.remove(webSocket);
            print(chalk.yellow('📱 WebSocket client disconnected'));
          },
          onError: (error) {
            webSocketClients.remove(webSocket);
            logger.warning('WebSocket error: $error');
          },
        );
      }),
    );

    // Static file serving
    final staticHandler = createStaticHandler(
      'web',
      defaultDocument: 'index.html',
    );

    // Combine handlers
    final handler = shelf.Cascade().add(router.call).add(staticHandler).handler;

    // Start server
    final server = await serve(handler, InternetAddress.loopbackIPv4, port);

    print(chalk.green('🌐 Web server started!'));
    print(chalk.green('📱 Visit: http://localhost:$port'));
    print(chalk.gray('Press Ctrl+C to stop'));

    // Keep running
    ProcessSignal.sigint.watch().listen((signal) {
      print(chalk.yellow('\n🛑 Shutting down server...'));
      server.close(force: true);
      exit(0);
    });
  }

  Future<void> _setupNotificationListener() async {
    // Listen for file sharing notifications (original functionality)
    atClient.notificationService
        .subscribe(regex: '$nameSpace:file_share', shouldDecrypt: true)
        .listen((notification) async {
          try {
            await _handleNotification(notification);
          } catch (e) {
            logger.severe('Error handling notification: $e');
          }
        });

    // Listen for file summary notifications (fallback for processed files)
    atClient.notificationService
        .subscribe(regex: 'file_summary.$nameSpace', shouldDecrypt: true)
        .listen((notification) async {
          print(chalk.cyan('🔔 Received file summary notification: ${notification.key}'));
          print(chalk.gray('📨 From: ${notification.from}'));
          try {
            await _handleFileSummaryNotification(notification);
          } catch (e) {
            logger.severe('Error handling file summary notification: $e');
          }
        });

    // Listen for web frontend data notifications (processed files)
    atClient.notificationService
        .subscribe(regex: '$nameSpace:web_frontend_data', shouldDecrypt: false)
        .listen((notification) async {
          print(chalk.cyan('🔔 Received web frontend notification: ${notification.key}'));
          print(chalk.gray('📨 From: ${notification.from}'));
          print(chalk.gray('📄 Value: ${notification.value?.substring(0, 100)}...'));
          try {
            await _handleWebFrontendNotification(notification);
          } catch (e) {
            logger.severe('Error handling web frontend notification: $e');
          }
        });

    // Debug: Listen for ALL notifications to see what's coming through
    atClient.notificationService
        .subscribe(regex: '$nameSpace', shouldDecrypt: false)
        .listen((notification) async {
          print(chalk.magenta('🔍 DEBUG - All notifications: ${notification.key}'));
          print(chalk.gray('📨 From: ${notification.from}'));
        });

    print(chalk.green('🔔 Listening for file processing notifications...'));
  }

  Future<void> _handleNotification(AtNotification notification) async {
    try {
      if (notification.value == null) return;

      final data = jsonDecode(notification.value!);

      // Check if this is a response notification (contains summary)
      if (data['summary'] != null) {
        final processedFile = ProcessedFile(
          id: Uuid().v4(),
          filename: data['filename'] ?? 'Unknown File',
          originalData: data['original_data'],
          summary: data['summary'],
          processedAt: DateTime.now(),
          sender: notification.from,
          fileSize: data['file_size'],
          fileType: data['file_type'],
          ocrText: data['ocr_text'],
        );

        processedFiles.insert(
          0,
          processedFile,
        ); // Add to beginning for newest first

        // Keep only last 100 files
        if (processedFiles.length > 100) {
          processedFiles.removeRange(100, processedFiles.length);
        }

        print(chalk.green('📄 New file processed: ${processedFile.filename}'));

        // Broadcast to WebSocket clients
        _broadcastToClients({
          'type': 'new_file',
          'file': processedFile.toJson(),
        });
      }
    } catch (e) {
      logger.severe('Error processing notification: $e');
    }
  }

  Future<void> _handleFileSummaryNotification(AtNotification notification) async {
    try {
      print(chalk.yellow('🔍 Processing file summary notification...'));
      print(chalk.gray('Key: ${notification.key}'));
      print(chalk.gray('From: ${notification.from}'));
      print(chalk.gray('To: ${notification.to}'));
      print(chalk.gray('Raw Value: ${notification.value}'));
      
      if (notification.value == null || notification.value!.isEmpty) {
        print(chalk.red('❌ Notification value is null or empty'));
        return;
      }

      try {
        final data = jsonDecode(notification.value!);
        print(chalk.gray('Parsed data: ${data.toString()}'));
        
        // Check if this is a summary notification (successful processing)
        if (data['filename'] != null && data['summary'] != null) {
          final filename = data['filename'];
          final summary = data['summary'];
          
          // Check if we already have this file to avoid duplicates
          final existingFile = processedFiles.where((file) => 
            file.filename == filename && 
            file.summary == summary
          );
          
          if (existingFile.isNotEmpty) {
            print(chalk.yellow('⚠️ File already exists in dashboard: $filename'));
            return;
          }
          
          final processedFile = ProcessedFile(
            id: Uuid().v4(),
            filename: filename,
            originalData: null, // File summary notifications don't include original data
            summary: summary,
            processedAt: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
            sender: data['agent'] ?? notification.from,
            fileSize: null,
            fileType: _getFileType(filename),
            ocrText: null,
          );

          processedFiles.insert(0, processedFile); // Add to beginning for newest first
          
          // Keep only last 100 files
          if (processedFiles.length > 100) {
            processedFiles.removeRange(100, processedFiles.length);
          }

          print(chalk.green('📄 File summary received: ${processedFile.filename}'));
          print(chalk.blue('📊 Total files now: ${processedFiles.length}'));
          
          // Broadcast to WebSocket clients
          _broadcastToClients({
            'type': 'new_file',
            'file': processedFile.toJson(),
          });
          print(chalk.green('📡 Broadcasted to ${webSocketClients.length} WebSocket clients'));
        } else if (data['error'] != null || data['status'] == 'failed') {
          // Handle failed processing notifications
          print(chalk.red('❌ File processing failed:'));
          print(chalk.red('   Error: ${data['error'] ?? 'Unknown error'}'));
          print(chalk.red('   File: ${data['filename'] ?? 'Unknown file'}'));
          // Don't add failed processing to the dashboard
        } else {
          print(chalk.red('❌ Missing filename or summary in notification data'));
          print(chalk.gray('Available fields: ${data.keys.join(', ')}'));
        }
      } catch (jsonError) {
        print(chalk.red('❌ Failed to parse JSON: $jsonError'));
        print(chalk.gray('Raw value was: ${notification.value}'));
        
        // Maybe the notification value is just a string (error message)?
        if (notification.value!.toLowerCase().contains('error') || 
            notification.value!.toLowerCase().contains('fail')) {
          print(chalk.red('❌ Looks like an error notification: ${notification.value}'));
        } else {
          print(chalk.yellow('⚠️ Unexpected notification format'));
        }
      }
    } catch (e) {
      logger.severe('Error processing file summary notification: $e');
      print(chalk.red('❌ Error processing file summary: $e'));
    }
  }

  Future<void> _handleWebFrontendNotification(
    AtNotification notification,
  ) async {
    try {
      if (notification.value == null) return;

      final data = jsonDecode(notification.value!);

      // Check if this is a processed file notification
      if (data['type'] == 'processed_file') {
        final processedFile = ProcessedFile(
          id: Uuid().v4(),
          filename: data['filename'] ?? 'Unknown File',
          originalData: data['fileData'], // Base64 encoded file data
          summary: data['summary'],
          processedAt: DateTime.parse(
            data['processedAt'] ?? DateTime.now().toIso8601String(),
          ),
          sender: data['agent'] ?? 'Unknown Agent',
          fileSize: data['fileSize'],
          fileType: _getFileType(data['filename']),
          ocrText: null, // Will be null for LLM summarized files
        );

        processedFiles.insert(
          0,
          processedFile,
        ); // Add to beginning for newest first

        // Keep only last 100 files
        if (processedFiles.length > 100) {
          processedFiles.removeRange(100, processedFiles.length);
        }

        print(
          chalk.green(
            '📄 New file processed: ${processedFile.filename} (${processedFile.fileSize} bytes)',
          ),
        );

        // Broadcast to WebSocket clients
        _broadcastToClients({
          'type': 'new_file',
          'file': processedFile.toJson(),
        });
      }
    } catch (e) {
      logger.severe('Error processing web frontend notification: $e');
    }
  }

  String _getFileType(String? filename) {
    if (filename == null) return 'unknown';

    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'txt':
        return 'Text File';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xls':
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint Presentation';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'Image';
      default:
        return 'Document';
    }
  }

  void _broadcastToClients(Map<String, dynamic> message) {
    final jsonMessage = jsonEncode(message);
    final clientsToRemove = <WebSocketChannel>[];

    for (final client in webSocketClients) {
      try {
        client.sink.add(jsonMessage);
      } catch (e) {
        clientsToRemove.add(client);
      }
    }

    // Remove failed clients
    for (final client in clientsToRemove) {
      webSocketClients.remove(client);
    }
  }

  Future<shelf.Response> _handleGetFiles(shelf.Request request) async {
    final filesJson = processedFiles.map((f) => f.toJson()).toList();
    return shelf.Response.ok(
      jsonEncode(filesJson),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<shelf.Response> _handleGetFile(shelf.Request request) async {
    final fileId = request.params['fileId']!;
    final file = processedFiles.firstWhere(
      (f) => f.id == fileId,
      orElse: () => throw StateError('File not found'),
    );

    return shelf.Response.ok(
      jsonEncode(file.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<shelf.Response> _handleDownloadFile(shelf.Request request) async {
    try {
      final fileId = request.params['fileId']!;
      final file = processedFiles.firstWhere(
        (f) => f.id == fileId,
        orElse: () => throw StateError('File not found'),
      );

      if (file.originalData == null) {
        return shelf.Response.notFound('Original file data not available');
      }

      // Decode base64 data
      final bytes = base64Decode(file.originalData!);

      return shelf.Response.ok(
        bytes,
        headers: {
          'Content-Type': 'application/pdf',
          'Content-Disposition': 'attachment; filename="${file.filename}"',
        },
      );
    } catch (e) {
      logger.severe('Error downloading file: $e');
      return shelf.Response.internalServerError(
        body: 'Error downloading file: $e',
      );
    }
  }
}

/// Represents a processed file with its summary
class ProcessedFile {
  final String id;
  final String filename;
  final String? originalData; // Base64 encoded file data
  final String summary;
  final DateTime processedAt;
  final String sender;
  final int? fileSize;
  final String? fileType;
  final String? ocrText;

  ProcessedFile({
    required this.id,
    required this.filename,
    this.originalData,
    required this.summary,
    required this.processedAt,
    required this.sender,
    this.fileSize,
    this.fileType,
    this.ocrText,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'summary': summary,
    'processedAt': processedAt.toIso8601String(),
    'sender': sender,
    'fileSize': fileSize,
    'fileType': fileType,
    'hasOriginalData': originalData != null,
    'ocrText': ocrText,
  };
}
