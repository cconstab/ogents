import 'dart:async';
import 'dart:convert';

import 'package:at_client/at_client.dart';
import 'package:at_utils/at_logger.dart';
import 'package:uuid/uuid.dart';

/// Handles communication with LLM services via atSigns
class LLMClient {
  final AtClient atClient;
  final String nameSpace;
  final String llmAtSign;
  final logger = AtSignLogger('LLMClient');

  static const String llmRequestKey = 'llm_request';
  static const String llmResponseKey = 'llm_response';

  LLMClient({
    required this.atClient,
    required this.nameSpace,
    required this.llmAtSign,
  });

  /// Sends a request to the LLM service and waits for response
  Future<String?> sendToLLM(String prompt, String originalSender) async {
    try {
      final requestId = Uuid().v4();

      logger.info('Sending LLM request $requestId to $llmAtSign');

      // Prepare the request
      final requestData = {
        'id': requestId,
        'prompt': prompt,
        'sender': originalSender,
        'agent': atClient.getCurrentAtSign(),
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'file_summarization',
      };

      // Send request to LLM service
      final success = await _sendLLMRequest(requestData);
      if (!success) {
        logger.warning('Failed to send LLM request');
        return null;
      }

      // Wait for response
      return await _waitForLLMResponse(requestId);
    } catch (e, stackTrace) {
      logger.severe('Error sending to LLM: $e', e, stackTrace);
      return null;
    }
  }

  Future<bool> _sendLLMRequest(Map<String, dynamic> requestData) async {
    try {
      final key = AtKey()
        ..key = llmRequestKey
        ..sharedBy = atClient.getCurrentAtSign()
        ..sharedWith = llmAtSign
        ..namespace = nameSpace
        ..metadata = (Metadata()
          ..isEncrypted = true
          ..isPublic = false
          ..namespaceAware = true
          ..ttl = 300000); // 5 minutes TTL

      final result = await atClient.notificationService.notify(
        NotificationParams.forUpdate(key, value: jsonEncode(requestData)),
        checkForFinalDeliveryStatus: false,
      );

      if (result.atClientException != null) {
        logger.warning(
          'LLM request notification failed: ${result.atClientException}',
        );
        return false;
      }

      logger.info('LLM request sent successfully');
      return true;
    } catch (e) {
      logger.severe('Error sending LLM request: $e');
      return false;
    }
  }

  Future<String?> _waitForLLMResponse(String requestId) async {
    final completer = Completer<String?>();
    StreamSubscription? subscription;
    Timer? timeout;

    try {
      // Subscribe to LLM responses
      final regex = '$llmResponseKey\\.$nameSpace@';

      subscription = atClient.notificationService
          .subscribe(regex: regex, shouldDecrypt: true)
          .listen((notification) {
            try {
              final responseData =
                  jsonDecode(notification.value!) as Map<String, dynamic>;
              final responseId = responseData['request_id'] as String?;

              if (responseId == requestId) {
                final response = responseData['response'] as String?;
                if (response != null) {
                  logger.info('Received LLM response for request $requestId');
                  if (!completer.isCompleted) {
                    completer.complete(response);
                  }
                } else {
                  logger.warning('LLM response missing response field');
                  if (!completer.isCompleted) {
                    completer.complete(null);
                  }
                }
              }
            } catch (e) {
              logger.warning('Error parsing LLM response: $e');
            }
          });

      // Set timeout
      timeout = Timer(Duration(seconds: 60), () {
        logger.warning('LLM response timeout for request $requestId');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      logger.severe('Error waiting for LLM response: $e');
      return null;
    } finally {
      subscription?.cancel();
      timeout?.cancel();
    }
  }

  /// Starts listening for LLM requests (used when this agent acts as an LLM service)
  Future<void> startLLMService({
    required Future<String?> Function(
      String prompt,
      Map<String, dynamic> context,
    )
    onRequest,
  }) async {
    final regex = '$llmRequestKey\\.$nameSpace@';

    logger.info('Starting LLM service, listening for: $regex');

    atClient.notificationService
        .subscribe(regex: regex, shouldDecrypt: true)
        .listen(
          (notification) async {
            await _handleLLMRequest(notification, onRequest);
          },
          onError: (error) {
            logger.severe('LLM service error: $error');
          },
        );
  }

  Future<void> _handleLLMRequest(
    AtNotification notification,
    Future<String?> Function(String prompt, Map<String, dynamic> context)
    onRequest,
  ) async {
    try {
      final requestData =
          jsonDecode(notification.value!) as Map<String, dynamic>;
      final requestId = requestData['id'] as String;
      final prompt = requestData['prompt'] as String;
      final sender = notification.from;

      logger.info('Processing LLM request $requestId from $sender');

      // Process the request
      final response = await onRequest(prompt, requestData);

      if (response != null) {
        // Send response back
        await _sendLLMResponse(sender, requestId, response);
        logger.info('LLM response sent for request $requestId');
      } else {
        logger.warning('LLM processing failed for request $requestId');
        await _sendLLMResponse(
          sender,
          requestId,
          'Sorry, I was unable to process your request.',
        );
      }
    } catch (e, stackTrace) {
      logger.severe('Error handling LLM request: $e', e, stackTrace);
    }
  }

  Future<void> _sendLLMResponse(
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
