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

import 'package:ogents/src/database_service.dart';

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
  final Set<WebSocketChannel> webSocketClients = {};
  late AppDatabase database;

  WebServer({
    required this.atClient,
    required this.nameSpace,
    required this.port,
  });

  Future<void> start() async {
    // Initialize database
    database = AppDatabase();
    print(chalk.blue('📊 Database initialized'));

    // Setup notification listener
    await _setupNotificationListener();

    // Setup router
    final router = Router();

    // API endpoints
    router.get('/api/files', _handleGetFiles);
    router.get('/api/files/<fileId>/download', _handleDownloadFile);
    router.get('/api/files/<fileId>', _handleGetFile);
    router.get('/api/stats', _handleGetStats);
    router.get('/api/search', _handleSearchFiles);
    router.get('/api/calendar', _handleGetCalendarData);
    router.get('/api/files/date/<date>', _handleGetFilesByDate);
    router.delete('/api/files/<fileId>', _handleDeleteFile);
    router.delete('/api/files/cleanup/<days>', _handleCleanupOldFiles);
    router.post('/api/files/<fileId>/extract-title', _handleExtractTitle);

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
    ProcessSignal.sigint.watch().listen((signal) async {
      print(chalk.yellow('\n🛑 Shutting down server...'));
      await database.close();
      server.close(force: true);
      exit(0);
    });
  }

  Future<void> _setupNotificationListener() async {
    // The web frontend should NOT process file_share notifications directly.
    // That's handled by the main ogents file agent. The web frontend only
    // listens for the processed results.

    // The web frontend should NOT process file_summary notifications.
    // file_summary notifications are sent back to the original file sender.
    // The web frontend only processes web_frontend_data notifications.

    // Listen for web frontend data notifications (processed files)
    atClient.notificationService
        .subscribe(regex: 'web_frontend_data.$nameSpace', shouldDecrypt: true)
        .listen((notification) async {
          print(
            chalk.cyan(
              '🔔 Received web frontend notification: ${notification.key}',
            ),
          );
          print(chalk.gray('📨 From: ${notification.from}'));
          print(
            chalk.gray('📄 Value: ${notification.value?.substring(0, 100)}...'),
          );
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
          print(
            chalk.magenta('🔍 DEBUG - All notifications: ${notification.key}'),
          );
          print(chalk.gray('📨 From: ${notification.from}'));
        });

    print(chalk.green('🔔 Listening for file processing notifications...'));
  }

  Future<void> _handleWebFrontendNotification(
    AtNotification notification,
  ) async {
    try {
      if (notification.value == null) return;

      final data = jsonDecode(notification.value!);

      // Check if this is a processed file notification
      if (data['type'] == 'processed_file') {
        var processedFile = ProcessedFileModel(
          id: Uuid().v4(),
          filename: data['filename'] ?? 'Unknown File',
          originalData: data['fileData'] != null
              ? base64Decode(data['fileData'])
              : null, // Decode base64 to bytes
          summary: data['summary'],
          processedAt: DateTime.parse(
            data['processedAt'] ?? DateTime.now().toIso8601String(),
          ),
          sender: data['agent'] ?? 'Unknown Agent',
          fileSize: data['fileSize'],
          fileType: _getFileType(data['filename']),
          ocrText: null, // Will be null for LLM summarized files
          agentAtSign: data['agent'],
        );

        // Save to database
        await database.insertProcessedFile(processedFile.toDbCompanion());

        // Extract title automatically for new files
        final extractedTitle = await _extractTitleFromSummary(
          processedFile.summary,
        );
        if (extractedTitle != null) {
          await database.updateFileTitle(processedFile.id, extractedTitle);
          processedFile = ProcessedFileModel(
            id: processedFile.id,
            filename: processedFile.filename,
            originalData: processedFile.originalData,
            summary: processedFile.summary,
            title: extractedTitle,
            processedAt: processedFile.processedAt,
            sender: processedFile.sender,
            fileSize: processedFile.fileSize,
            fileType: processedFile.fileType,
            ocrText: processedFile.ocrText,
            agentAtSign: processedFile.agentAtSign,
          );
        }

        // Cleanup old files (keep only last 100)
        await database.cleanupOldFiles(keepCount: 100);

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
    try {
      final files = await database.getAllProcessedFiles();
      final filesJson = files
          .map((f) => ProcessedFileModel.fromDb(f).toJson())
          .toList();
      return shelf.Response.ok(
        jsonEncode(filesJson),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      logger.severe('Error getting files: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get files: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<shelf.Response> _handleGetFile(shelf.Request request) async {
    try {
      final fileId = request.params['fileId']!;
      final file = await database.getProcessedFileById(fileId);

      if (file == null) {
        return shelf.Response.notFound(
          jsonEncode({'error': 'File not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return shelf.Response.ok(
        jsonEncode(ProcessedFileModel.fromDb(file).toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      logger.severe('Error getting file: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get file: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<shelf.Response> _handleDownloadFile(shelf.Request request) async {
    try {
      final fileId = request.params['fileId']!;
      final file = await database.getProcessedFileById(fileId);

      if (file == null) {
        return shelf.Response.notFound('File not found');
      }

      if (file.originalData == null) {
        return shelf.Response.notFound('Original file data not available');
      }

      return shelf.Response.ok(
        file.originalData!,
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

  Future<shelf.Response> _handleGetStats(shelf.Request request) async {
    try {
      final stats = await database.getStats();
      return shelf.Response.ok(
        jsonEncode(stats),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      logger.severe('Error getting stats: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get stats: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<shelf.Response> _handleSearchFiles(shelf.Request request) async {
    try {
      final query = request.url.queryParameters['q'];
      if (query == null || query.isEmpty) {
        return shelf.Response.badRequest(
          body: jsonEncode({'error': 'Query parameter "q" is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final files = await database.searchFiles(query);
      final filesJson = files
          .map((f) => ProcessedFileModel.fromDb(f).toJson())
          .toList();

      return shelf.Response.ok(
        jsonEncode({
          'query': query,
          'results': filesJson,
          'count': filesJson.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      logger.severe('Error searching files: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': 'Failed to search files: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<shelf.Response> _handleGetCalendarData(shelf.Request request) async {
    try {
      final groupedFiles = await database.getFilesGroupedByDate();

      // Convert to calendar format
      final calendarData = <String, dynamic>{};
      for (final entry in groupedFiles.entries) {
        calendarData[entry.key] = {
          'count': entry.value.length,
          'files': entry.value
              .map((f) => ProcessedFileModel.fromDb(f).toJson())
              .toList(),
        };
      }

      return shelf.Response.ok(
        jsonEncode(calendarData),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      logger.severe('Error getting calendar data: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get calendar data: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<shelf.Response> _handleGetFilesByDate(shelf.Request request) async {
    try {
      final dateStr = request.params['date']!;
      final date = DateTime.parse(dateStr);
      final nextDay = date.add(Duration(days: 1));

      final files = await database.getFilesByDateRange(date, nextDay);
      final filesJson = files
          .map((f) => ProcessedFileModel.fromDb(f).toJson())
          .toList();

      return shelf.Response.ok(
        jsonEncode({
          'date': dateStr,
          'files': filesJson,
          'count': filesJson.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      logger.severe('Error getting files by date: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get files by date: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<shelf.Response> _handleDeleteFile(shelf.Request request) async {
    try {
      final fileId = request.params['fileId']!;
      final deleted = await database.deleteFileById(fileId);

      if (deleted) {
        // Broadcast deletion to WebSocket clients
        _broadcastToClients({'type': 'file_deleted', 'fileId': fileId});

        return shelf.Response.ok(
          jsonEncode({'success': true, 'message': 'File deleted successfully'}),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return shelf.Response.notFound(
          jsonEncode({'error': 'File not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      logger.severe('Error deleting file: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete file: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<shelf.Response> _handleCleanupOldFiles(shelf.Request request) async {
    try {
      final daysStr = request.params['days']!;
      final days = int.parse(daysStr);
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final deletedCount = await database.deleteFilesOlderThan(cutoffDate);

      // Broadcast cleanup to WebSocket clients
      _broadcastToClients({
        'type': 'files_cleaned',
        'deletedCount': deletedCount,
        'cutoffDate': cutoffDate.toIso8601String(),
      });

      return shelf.Response.ok(
        jsonEncode({
          'success': true,
          'deletedCount': deletedCount,
          'message': 'Deleted $deletedCount files older than $days days',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      logger.severe('Error cleaning up old files: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': 'Failed to cleanup old files: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<shelf.Response> _handleExtractTitle(shelf.Request request) async {
    try {
      final fileId = request.params['fileId']!;
      final file = await database.getProcessedFileById(fileId);

      if (file == null) {
        return shelf.Response.notFound(
          jsonEncode({'error': 'File not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Extract title using LLM based on summary
      final extractedTitle = await _extractTitleFromSummary(file.summary);

      if (extractedTitle != null) {
        await database.updateFileTitle(fileId, extractedTitle);

        // Broadcast title update to WebSocket clients
        _broadcastToClients({
          'type': 'title_updated',
          'fileId': fileId,
          'title': extractedTitle,
        });

        return shelf.Response.ok(
          jsonEncode({
            'success': true,
            'title': extractedTitle,
            'message': 'Title extracted and updated successfully',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return shelf.Response.internalServerError(
          body: jsonEncode({'error': 'Failed to extract title from summary'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      logger.severe('Error extracting title: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': 'Failed to extract title: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Extract a title from the document summary using simple heuristics
  Future<String?> _extractTitleFromSummary(String summary) async {
    try {
      // Simple title extraction - take the first sentence or up to first period
      final sentences = summary.split('.');
      if (sentences.isNotEmpty) {
        String title = sentences[0].trim();

        // Clean up the title
        title = title.replaceAll(
          RegExp(r'^(this|the|a|an)\s+', caseSensitive: false),
          '',
        );
        title = title.replaceAll(RegExp(r'\s+'), ' ');

        // Capitalize first letter
        if (title.isNotEmpty) {
          title = title[0].toUpperCase() + title.substring(1);
        }

        // Limit length
        if (title.length > 100) {
          title = title.substring(0, 97) + '...';
        }

        return title.isNotEmpty ? title : null;
      }

      return null;
    } catch (e) {
      logger.severe('Error extracting title from summary: $e');
      return null;
    }
  }
}
