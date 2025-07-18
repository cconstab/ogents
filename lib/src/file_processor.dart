import 'dart:io';
import 'dart:convert';

import 'package:at_client/at_client.dart';
import 'package:at_utils/at_logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:mime/mime.dart';

/// Handles file download and processing operations
class FileProcessor {
  final AtClient atClient;
  final String nameSpace;
  final String downloadPath;
  final logger = AtSignLogger('FileProcessor');

  FileProcessor({
    required this.atClient,
    required this.nameSpace,
    required this.downloadPath,
  }) {
    _ensureDownloadDirectory();
  }

  void _ensureDownloadDirectory() {
    final dir = Directory(downloadPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Downloads a file based on file information from notification
  Future<File?> downloadFile(
    String fromAtSign,
    Map<String, dynamic> fileInfo,
  ) async {
    try {
      final filename = fileInfo['filename'] as String;
      final fileUrl = fileInfo['url'] as String?;
      final fileData = fileInfo['data'] as String?;
      final transferId = fileInfo['transferId'] as String?;

      File? downloadedFile;

      if (fileUrl != null) {
        // Download from URL
        downloadedFile = await _downloadFromUrl(fileUrl, filename);
      } else if (fileData != null) {
        // Extract from base64 data
        downloadedFile = await _extractFromBase64(fileData, filename);
      } else if (transferId != null) {
        // Download using atPlatform file transfer
        downloadedFile = await _downloadViaAtPlatform(fromAtSign, transferId);
      } else {
        // Try to get file from shared key
        downloadedFile = await _downloadFromSharedKey(fromAtSign, filename);
      }

      return downloadedFile;
    } catch (e, stackTrace) {
      logger.severe('Error downloading file: $e', e, stackTrace);
      return null;
    }
  }

  Future<File?> _downloadFromUrl(String url, String filename) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(path.join(downloadPath, filename));
        await file.writeAsBytes(response.bodyBytes);
        logger.info('File downloaded from URL: ${file.path}');
        return file;
      } else {
        logger.warning(
          'HTTP error ${response.statusCode} downloading from URL: $url',
        );
        return null;
      }
    } catch (e) {
      logger.severe('Error downloading from URL: $e');
      return null;
    }
  }

  Future<File?> _extractFromBase64(String base64Data, String filename) async {
    try {
      final bytes = base64Decode(base64Data);
      final file = File(path.join(downloadPath, filename));
      await file.writeAsBytes(bytes);
      logger.info('File extracted from base64: ${file.path}');
      return file;
    } catch (e) {
      logger.severe('Error extracting from base64: $e');
      return null;
    }
  }

  Future<File?> _downloadViaAtPlatform(
    String fromAtSign,
    String transferId,
  ) async {
    try {
      // Use atClient's file download capability
      final files = await atClient.downloadFile(
        transferId,
        fromAtSign,
        downloadPath: downloadPath,
      );
      if (files.isNotEmpty) {
        logger.info('File downloaded via atPlatform: ${files.first.path}');
        return files.first;
      }
      return null;
    } catch (e) {
      logger.warning('Error downloading via atPlatform: $e');
      return null;
    }
  }

  Future<File?> _downloadFromSharedKey(
    String fromAtSign,
    String filename,
  ) async {
    try {
      // Try to get file data from a shared key
      final fileKey = AtKey()
        ..key = 'file_data_$filename'
        ..sharedBy = fromAtSign
        ..sharedWith = atClient.getCurrentAtSign()
        ..namespace = nameSpace;

      final result = await atClient.get(fileKey);
      if (result.value != null) {
        // Assume the value is base64 encoded file data
        return await _extractFromBase64(result.value, filename);
      }
      return null;
    } catch (e) {
      logger.warning('Error downloading from shared key: $e');
      return null;
    }
  }

  /// Extracts text content from various file types
  Future<String> extractTextContent(File file) async {
    try {
      final mimeType = lookupMimeType(file.path);
      final extension = path.extension(file.path).toLowerCase();

      logger.info(
        'Processing file: ${file.path}, MIME type: $mimeType, extension: $extension',
      );

      // Handle different file types
      switch (extension) {
        case '.txt':
        case '.md':
        case '.log':
        case '.csv':
        case '.json':
        case '.xml':
        case '.yaml':
        case '.yml':
          return await _extractPlainText(file);

        case '.pdf':
          return await _extractPdfText(file);

        case '.doc':
        case '.docx':
          return await _extractDocumentText(file);

        case '.zip':
        case '.tar':
        case '.gz':
          return await _extractArchiveText(file);

        default:
          // Try to read as plain text, limiting size
          return await _extractPlainTextSafe(file);
      }
    } catch (e) {
      logger.warning('Error extracting text content: $e');
      return 'Unable to extract text content from file: ${file.path}';
    }
  }

  Future<String> _extractPlainText(File file) async {
    try {
      final content = await file.readAsString();
      // Limit content size to avoid overwhelming the LLM
      const maxLength = 50000; // 50KB of text
      if (content.length > maxLength) {
        return content.substring(0, maxLength) + '\\n\\n[Content truncated...]';
      }
      return content;
    } catch (e) {
      logger.warning('Error reading plain text: $e');
      return 'Unable to read file as text';
    }
  }

  Future<String> _extractPlainTextSafe(File file) async {
    try {
      // Read first 50KB and check if it's mostly text
      const maxBytes = 50000;
      final bytes = await file.readAsBytes();
      final limitedBytes = bytes.take(maxBytes).toList();

      // Check if content is mostly printable ASCII/UTF-8
      final text = utf8.decode(limitedBytes, allowMalformed: true);
      final printableChars = text.runes
          .where((r) => r >= 32 && r <= 126 || r == 10 || r == 13)
          .length;
      final ratio = printableChars / text.length;

      if (ratio > 0.8) {
        // Likely text content
        return text +
            (bytes.length > maxBytes ? '\\n\\n[Content truncated...]' : '');
      } else {
        return 'Binary file detected. Unable to extract meaningful text content.';
      }
    } catch (e) {
      logger.warning('Error reading file safely: $e');
      return 'Unable to read file content';
    }
  }

  Future<String> _extractPdfText(File file) async {
    // For PDF extraction, you would typically use a library like pdf_text or similar
    // For now, return a placeholder
    return 'PDF file detected. Text extraction not implemented. File: ${file.path}';
  }

  Future<String> _extractDocumentText(File file) async {
    // For DOC/DOCX extraction, you would use libraries like docx_to_text
    // For now, return a placeholder
    return 'Document file detected. Text extraction not implemented. File: ${file.path}';
  }

  Future<String> _extractArchiveText(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final textContents = <String>[];

      for (final file in archive) {
        if (file.isFile) {
          final filename = file.name;
          final extension = path.extension(filename).toLowerCase();

          if ([
            '.txt',
            '.md',
            '.log',
            '.csv',
            '.json',
            '.xml',
            '.yaml',
            '.yml',
          ].contains(extension)) {
            try {
              final content = utf8.decode(file.content as List<int>);
              textContents.add('--- File: $filename ---\\n$content\\n');
            } catch (e) {
              textContents.add(
                '--- File: $filename ---\\n[Unable to decode as text]\\n',
              );
            }
          }
        }
      }

      if (textContents.isEmpty) {
        return 'Archive file processed but no readable text files found.';
      }

      final combined = textContents.join('\\n');
      const maxLength = 50000;
      if (combined.length > maxLength) {
        return combined.substring(0, maxLength) +
            '\\n\\n[Content truncated...]';
      }

      return combined;
    } catch (e) {
      logger.warning('Error extracting archive: $e');
      return 'Archive file detected but could not be processed: ${file.path}';
    }
  }
}
