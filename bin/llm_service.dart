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
import 'package:http/http.dart' as http;

/// Simple LLM service that provides basic text summarization
void main(List<String> arguments) async {
  await runZonedGuarded(
    () async {
      await runLLMService(arguments);
    },
    (error, stackTrace) {
      stderr.writeln('Uncaught error: $error');
      stderr.writeln(stackTrace.toString());
      exit(1);
    },
  );
}

Future<void> runLLMService(List<String> args) async {
  // Setup logging
  AtSignLogger.defaultLoggingHandler = AtSignLogger.stdErrLoggingHandler;
  final logger = AtSignLogger('LLMService');
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

  final nameSpace = '${parsedArgs['namespace']}.ogents';
  final llmType = parsedArgs['llm-type'];
  final ollamaUrl = parsedArgs['ollama-url'];
  final ollamaModel = parsedArgs['ollama-model'];

  print(chalk.blue('Starting LLM Service...'));
  print(chalk.blue('Type: $llmType'));
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
            progName: 'ogents_llm',
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

  // Create LLM processor based on type
  late LLMProcessor processor;
  switch (llmType) {
    case 'ollama':
      processor = OllamaProcessor(ollamaUrl, ollamaModel);
      break;
    case 'simple':
    default:
      processor = SimpleLLMProcessor();
  }

  // Start the LLM service
  final service = LLMService(atClient, nameSpace, processor);
  await service.start();

  print(chalk.green('✅ LLM service is running'));
  print(chalk.gray('Press Ctrl+C to stop'));

  // Keep the program running
  while (true) {
    await Future.delayed(Duration(seconds: 1));
  }
}

ArgParser _createArgumentParser() {
  final parser = CLIBase.argsParser;

  parser.addOption(
    'llm-type',
    abbr: 't',
    help: 'Type of LLM to use (simple, ollama)',
    defaultsTo: 'simple',
    allowed: ['simple', 'ollama'],
  );

  parser.addOption(
    'ollama-url',
    help: 'URL for Ollama API',
    defaultsTo: 'http://localhost:11434',
  );

  parser.addOption(
    'ollama-model',
    help: 'Ollama model to use',
    defaultsTo: 'llama3.2',
  );

  return parser;
}

/// Abstract base class for LLM processors
abstract class LLMProcessor {
  Future<String> processPrompt(String prompt);
}

/// Simple rule-based text summarizer
class SimpleLLMProcessor implements LLMProcessor {
  @override
  Future<String> processPrompt(String prompt) async {
    // Extract the actual file content from the prompt
    final lines = prompt.split('\\n');
    final contentStartIndex = lines.indexWhere(
      (line) => line.contains('following file content:'),
    );

    if (contentStartIndex == -1 || contentStartIndex + 1 >= lines.length) {
      return 'Unable to extract file content for summarization.';
    }

    final content = lines.skip(contentStartIndex + 2).join('\\n').trim();

    if (content.isEmpty) {
      return 'No content found to summarize.';
    }

    return _generateSimpleSummary(content);
  }

  String _generateSimpleSummary(String content) {
    final words = content.split(RegExp(r'\\s+'));
    final sentences = content.split(RegExp(r'[.!?]+'));
    final lines = content.split('\\n');

    // Basic statistics
    final wordCount = words.where((w) => w.isNotEmpty).length;
    final sentenceCount = sentences.where((s) => s.trim().isNotEmpty).length;
    final lineCount = lines.length;

    // Extract key information using simple string concatenation
    final parts = <String>[];
    parts.add('📊 **Document Summary**\\n');
    parts.add('\\n');
    parts.add('**Statistics:**\\n');
    parts.add('- Lines: $lineCount\\n');
    parts.add('- Sentences: $sentenceCount\\n');
    parts.add('- Words: $wordCount\\n');
    parts.add('\\n');

    // Try to identify file type
    final fileType = _identifyFileType(content);
    parts.add('**File Type:** $fileType\\n');
    parts.add('\\n');

    // Extract key phrases (simple approach)
    final keyPhrases = _extractKeyPhrases(content);
    if (keyPhrases.isNotEmpty) {
      parts.add('**Key Terms:**\\n');
      for (final phrase in keyPhrases.take(10)) {
        parts.add('- $phrase\\n');
      }
      parts.add('\\n');
    }

    // Get first few sentences as preview
    final preview = sentences
        .where((s) => s.trim().isNotEmpty)
        .take(3)
        .map((s) => s.trim())
        .join(' ');

    if (preview.isNotEmpty) {
      parts.add('**Content Preview:**\\n');
      parts.add(
        preview.length > 300 ? '${preview.substring(0, 300)}...' : preview,
      );
    }

    return parts.join();
  }

  String _identifyFileType(String content) {
    if (content.contains('{') && content.contains('}')) {
      return 'JSON/Configuration';
    } else if (content.contains('<') && content.contains('>')) {
      return 'XML/HTML';
    } else if (content.contains('#') || content.contains('##')) {
      return 'Markdown';
    } else if (content.contains('import ') || content.contains('function ')) {
      return 'Source Code';
    } else if (content.contains(',') && content.split('\\n').length > 5) {
      return 'CSV/Data';
    }
    return 'Plain Text';
  }

  List<String> _extractKeyPhrases(String content) {
    // Simple keyword extraction
    final words = content
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z\\s]'), ' ')
        .split(RegExp(r'\\s+'))
        .where((w) => w.length > 3)
        .toList();

    // Count word frequency
    final frequency = <String, int>{};
    for (final word in words) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }

    // Common stop words to exclude
    final stopWords = {
      'this',
      'that',
      'with',
      'have',
      'will',
      'from',
      'they',
      'know',
      'want',
      'been',
      'good',
      'much',
      'some',
      'time',
      'very',
      'when',
      'come',
      'here',
      'just',
      'like',
      'long',
      'make',
      'many',
      'over',
      'such',
      'take',
      'than',
      'them',
      'well',
      'were',
      'what',
    };

    final results = frequency.entries
        .where((e) => e.value > 1 && !stopWords.contains(e.key))
        .toList();

    results.sort((a, b) => b.value.compareTo(a.value));

    return results.take(10).map((e) => '${e.key} (${e.value})').toList();
  }
}

/// Ollama-based LLM processor
class OllamaProcessor implements LLMProcessor {
  final String ollamaUrl;
  final String model;

  OllamaProcessor(this.ollamaUrl, this.model);

  @override
  Future<String> processPrompt(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$ollamaUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'model': model, 'prompt': prompt, 'stream': false}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['response'] ?? 'No response from Ollama';
      } else {
        return 'Error from Ollama API: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Failed to connect to Ollama: $e';
    }
  }
}

/// LLM service that handles requests from file agents
class LLMService {
  final AtClient atClient;
  final String nameSpace;
  final LLMProcessor processor;
  final logger = AtSignLogger('LLMService');

  static const String llmRequestKey = 'llm_request';
  static const String llmResponseKey = 'llm_response';

  LLMService(this.atClient, this.nameSpace, this.processor);

  Future<void> start() async {
    final regex = '$llmRequestKey\\.$nameSpace@';

    logger.info('Starting LLM service, listening for: $regex');
    print(chalk.blue('🔍 Listening for LLM requests matching: $regex'));

    atClient.notificationService
        .subscribe(regex: regex, shouldDecrypt: true)
        .listen(
          _handleRequest,
          onError: (error) {
            logger.severe('LLM service error: $error');
            print(chalk.red('❌ LLM service error: $error'));
          },
          onDone: () {
            logger.info('LLM service stopped');
            print(chalk.yellow('⚠️ LLM service stopped'));
          },
        );
  }

  Future<void> _handleRequest(AtNotification notification) async {
    try {
      final requestData =
          jsonDecode(notification.value!) as Map<String, dynamic>;
      final requestId = requestData['id'] as String;
      final prompt = requestData['prompt'] as String;
      final requestType = requestData['type'] as String?;
      final sender = notification.from;

      print(chalk.cyan('🤖 Processing LLM request $requestId from $sender'));
      print(chalk.gray('Type: $requestType'));
      logger.info('Processing LLM request $requestId from $sender');

      // Process the prompt
      final response = await processor.processPrompt(prompt);

      if (response.isNotEmpty) {
        // Send response back
        await _sendResponse(sender, requestId, response);
        print(chalk.green('✅ LLM response sent for request $requestId'));
        logger.info('LLM response sent for request $requestId');
      } else {
        logger.warning('Empty response for request $requestId');
        await _sendResponse(
          sender,
          requestId,
          'Sorry, I was unable to process your request.',
        );
      }
    } catch (e, stackTrace) {
      logger.severe('Error handling LLM request: $e', e, stackTrace);
      print(chalk.red('❌ Error processing LLM request: $e'));
    }
  }

  Future<void> _sendResponse(
    String toAtSign,
    String requestId,
    String response,
  ) async {
    try {
      final responseData = {
        'request_id': requestId,
        'response': response,
        'timestamp': DateTime.now().toIso8601String(),
        'llm_service': atClient.getCurrentAtSign(),
      };

      final key = AtKey()
        ..key = llmResponseKey
        ..sharedBy = atClient.getCurrentAtSign()
        ..sharedWith = toAtSign
        ..namespace = nameSpace
        ..metadata = (Metadata()
          ..isEncrypted = true
          ..isPublic = false
          ..namespaceAware = true
          ..ttl = 300000); // 5 minutes TTL

      final result = await atClient.notificationService.notify(
        NotificationParams.forUpdate(key, value: jsonEncode(responseData)),
        checkForFinalDeliveryStatus: false,
      );

      if (result.atClientException != null) {
        throw result.atClientException!;
      }
    } catch (e) {
      logger.severe('Error sending LLM response: $e');
      rethrow;
    }
  }
}
