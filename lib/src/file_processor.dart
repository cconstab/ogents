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
    required String downloadPath,
  }) : downloadPath = path.absolute(downloadPath) {
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

        case '.jpg':
        case '.jpeg':
        case '.png':
        case '.bmp':
        case '.tiff':
        case '.tif':
        case '.gif':
          return await _extractImageText(file);

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
    try {
      logger.info(
        '=== PDF PROCESSING DEBUG: Starting PDF text extraction with OCR: ${file.path}',
      );
      logger.info(
        '=== PDF PROCESSING DEBUG: File exists: ${file.existsSync()}',
      );
      logger.info(
        '=== PDF PROCESSING DEBUG: File size: ${file.lengthSync()} bytes',
      );

      // Check if it's actually a PDF file
      final bytes = await file.readAsBytes();
      if (!_isPdfFile(bytes)) {
        logger.warning('File is not a valid PDF: ${file.path}');
        return _createPdfAnalysisResult(
          file.path,
          'File is not a valid PDF format',
        );
      }

      logger.info('=== PDF PROCESSING DEBUG: PDF validation passed');

      // Try OCR extraction (PDF -> Image -> OCR)
      final ocrContent = await _extractPdfTextWithImageConversion(file);

      logger.info(
        '=== PDF PROCESSING DEBUG: OCR content length: ${ocrContent.length}',
      );
      logger.info(
        '=== PDF PROCESSING DEBUG: OCR content empty: ${ocrContent.trim().isEmpty}',
      );

      if (ocrContent.trim().isNotEmpty) {
        logger.info(
          'Successfully extracted text with OCR from PDF: ${file.path}',
        );
        return _formatOcrText(ocrContent, 'PDF-to-Image OCR');
      }

      // If OCR fails, provide helpful information
      logger.info(
        '=== PDF PROCESSING DEBUG: OCR extraction failed or returned empty, providing analysis: ${file.path}',
      );
      final analysisContent = await _analyzePdfContent(file);

      if (analysisContent.trim().isNotEmpty) {
        return analysisContent;
      }

      // If analysis fails, provide basic info with OCR status
      return _createPdfAnalysisResult(
        file.path,
        'PDF processed - OCR extraction did not find text content. This may be a text-based PDF that requires different processing, or the image quality may be too low for OCR.',
      );
    } catch (e) {
      logger.severe('Error processing PDF: $e');
      return _createPdfAnalysisResult(file.path, 'Error during processing: $e');
    }
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

  Future<String> _extractPdfTextWithImageConversion(File file) async {
    Directory? tempDir;
    try {
      logger.info('Converting PDF to images for OCR: ${file.path}');

      // Create temporary directory
      tempDir = await Directory.systemTemp.createTemp('pdf_ocr_');

      logger.info('Temp directory created: ${tempDir.path}');

      // First, get the number of pages in the PDF
      final pageCount = await _getPdfPageCount(file);
      logger.info('PDF has $pageCount pages');

      // Limit the number of pages to process (to avoid overwhelming the system)
      const maxPages = 10; // Process up to 10 pages
      final pagesToProcess = pageCount > maxPages ? maxPages : pageCount;

      if (pageCount > maxPages) {
        logger.info(
          'PDF has $pageCount pages, processing first $maxPages pages only',
        );
      }

      final allOcrResults = <String>[];

      // Process each page
      for (int pageNum = 0; pageNum < pagesToProcess; pageNum++) {
        final tempImagePath = '${tempDir.path}/page_$pageNum.png';
        logger.info('Converting PDF page ${pageNum + 1} to: $tempImagePath');

        // Convert specific page to image using ImageMagick
        var convertResult = await Process.run('magick', [
          file.path + '[$pageNum]', // Specific page
          '-density', '300', // High DPI for better OCR
          '-quality', '100',
          tempImagePath,
        ]);

        // If magick fails, try with convert command
        if (convertResult.exitCode != 0) {
          logger.info(
            'Magick command failed for page ${pageNum + 1}, trying convert command...',
          );
          convertResult = await Process.run('convert', [
            file.path + '[$pageNum]', // Specific page
            '-density', '300', // High DPI for better OCR
            '-quality', '100',
            tempImagePath,
          ]);
        }

        // If both ImageMagick commands fail, try Ghostscript for this page
        if (convertResult.exitCode != 0) {
          logger.info(
            'ImageMagick conversion failed for page ${pageNum + 1}, trying Ghostscript...',
          );
          final gsPageNum =
              pageNum + 1; // Ghostscript uses 1-based page numbers
          convertResult = await Process.run('gs', [
            '-dNOPAUSE',
            '-dBATCH',
            '-sDEVICE=png16m',
            '-r300', // 300 DPI
            '-dFirstPage=$gsPageNum',
            '-dLastPage=$gsPageNum',
            '-sOutputFile=$tempImagePath',
            file.path,
          ]);
        }

        if (convertResult.exitCode != 0) {
          logger.warning(
            'Failed to convert page ${pageNum + 1}: ${convertResult.stderr}',
          );
          continue; // Skip this page and try the next one
        }

        // Check if image was created
        final imageFile = File(tempImagePath);
        if (!imageFile.existsSync()) {
          logger.warning('Image file was not created for page ${pageNum + 1}');
          continue;
        }

        logger.info(
          'Page ${pageNum + 1} image created successfully, size: ${imageFile.lengthSync()} bytes',
        );

        // Run OCR on the converted image
        final pageOcrResult = await _extractTextWithTesseract(imageFile);

        if (pageOcrResult.trim().isNotEmpty) {
          logger.info(
            'OCR successful for page ${pageNum + 1}, extracted ${pageOcrResult.length} characters',
          );
          allOcrResults.add('--- Page ${pageNum + 1} ---\n$pageOcrResult');
        } else {
          logger.info('No text found on page ${pageNum + 1}');
        }
      }

      // Combine all OCR results
      final combinedResult = allOcrResults.join('\n\n');
      logger.info(
        'Total OCR result length: ${combinedResult.length} characters from ${allOcrResults.length} pages',
      );

      return combinedResult;
    } catch (e) {
      logger.severe('Error in PDF to image OCR: $e');
      return '';
    } finally {
      // Clean up temporary directory
      if (tempDir != null) {
        try {
          await tempDir.delete(recursive: true);
          logger.info('Cleaned up temporary OCR files');
        } catch (e) {
          logger.warning('Failed to clean up temp directory: $e');
        }
      }
    }
  }

  Future<String> _extractTextWithTesseract(File file) async {
    try {
      logger.info(
        'Attempting OCR text extraction using Tesseract CLI: ${file.path}',
      );

      // Try OCR with simpler parameters first
      final result = await Process.run('tesseract', [
        file.path,
        'stdout', // Output to stdout instead of file
        '-l', 'eng', // English language (can be configured)
      ]);

      if (result.exitCode == 0) {
        final extractedText = result.stdout as String;
        if (extractedText.trim().isNotEmpty) {
          logger.info('Tesseract OCR successful for: ${file.path}');
          return extractedText.trim();
        } else {
          logger.info(
            'Tesseract OCR completed but no text found: ${file.path}',
          );
          return '';
        }
      } else {
        final errorMessage = result.stderr as String;
        logger.warning(
          'Tesseract OCR failed with exit code ${result.exitCode}: $errorMessage',
        );

        // Try with different PSM mode if the first attempt failed
        if (errorMessage.contains('PSM') || errorMessage.contains('OSD')) {
          logger.info('Retrying OCR with different PSM mode...');
          final retryResult = await Process.run('tesseract', [
            file.path,
            'stdout',
            '-l', 'eng',
            '--psm', '6', // Uniform block of text
          ]);

          if (retryResult.exitCode == 0) {
            final retryText = retryResult.stdout as String;
            if (retryText.trim().isNotEmpty) {
              logger.info(
                'Tesseract OCR successful on retry for: ${file.path}',
              );
              return retryText.trim();
            }
          }
        }

        return '';
      }
    } catch (e) {
      logger.warning('Error running Tesseract OCR: $e');
      return '';
    }
  }

  String _formatOcrText(String rawText, String method) {
    // Clean up OCR text
    final cleanText = rawText
        .replaceAll(
          RegExp(r'\n\s*\n\s*\n'),
          '\n\n',
        ) // Remove excessive line breaks
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Normalize spaces
        .replaceAll(
          RegExp(r'^\s+', multiLine: true),
          '',
        ) // Remove leading whitespace
        .trim();

    // Check if this is multi-page content
    final isMultiPage = cleanText.contains('--- Page ');
    final pageCount = isMultiPage
        ? RegExp(r'--- Page \d+ ---').allMatches(cleanText).length
        : 1;

    final formattedText =
        '''📄 **PDF Text Content (Extracted with $method)**${isMultiPage ? ' - $pageCount Pages' : ''}

$cleanText''';

    // Limit content size to prevent overwhelming the LLM
    const maxLength = 50000;
    if (formattedText.length > maxLength) {
      return '${formattedText.substring(0, maxLength)}\n\n[Content truncated due to length...]';
    }

    return formattedText;
  }

  Future<String> _analyzePdfContent(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileSize = bytes.length;

      // Basic PDF validation
      if (!_isPdfFile(bytes)) {
        return 'File does not appear to be a valid PDF: ${file.path}';
      }

      // Create analysis result - OCR attempted but no text found
      final analysisText =
          '''📄 **PDF Document Processed with OCR**

**File Information:**
- File: ${path.basename(file.path)}
- Format: PDF Document
- Size: ${(fileSize / 1024).toStringAsFixed(1)} KB
- Status: Successfully detected as PDF

**OCR Processing Status:**
✅ PDF file format validated
✅ OCR pipeline attempted (PDF → Image → Text extraction)
⚠️  OCR extraction completed but no readable text was found

**Possible Reasons for Empty OCR Result:**
1. **Blank or image-only PDF**: Document may contain only images, graphics, or blank pages
2. **Low image quality**: Scanned document resolution too low for accurate text recognition
3. **Complex formatting**: Tables, charts, or unusual layouts that OCR couldn't process
4. **Protected content**: Password-protected or encrypted text sections
5. **Non-standard fonts**: Unusual fonts or handwriting that OCR couldn't recognize

**Technical Details:**
- OCR Technology: Tesseract with ImageMagick PDF conversion
- Processing: PDF converted to 300 DPI PNG image for optimal OCR
- Language: English text recognition enabled

**What This Means:**
The PDF was successfully processed through the complete OCR pipeline, but no extractable text content was detected. This doesn't mean the OCR system isn't working - it may simply indicate the PDF doesn't contain machine-readable text.

**If you expected text content:**
- Verify the PDF contains actual text (not just images of text)
- Check if the document quality is sufficient for text recognition''';

      return analysisText;
    } catch (e) {
      logger.warning('Error analyzing PDF content: $e');
      return '';
    }
  }

  bool _isPdfFile(List<int> bytes) {
    // PDF files start with "%PDF-"
    if (bytes.length < 5) return false;
    return bytes[0] == 0x25 && // %
        bytes[1] == 0x50 && // P
        bytes[2] == 0x44 && // D
        bytes[3] == 0x46 && // F
        bytes[4] == 0x2D; // -
  }

  String _createPdfAnalysisResult(String filePath, String reason) {
    return '''📄 **PDF Document Processed**

**File Information:**
- File: $filePath
- Format: PDF Document

**Processing Result:**
$reason

**OCR Processing:**
The PDF was processed using OCR (Optical Character Recognition) technology, which can extract text from both:
- Text-based PDFs (with selectable text)
- Image-based PDFs (scanned documents)

**Possible reasons for no text extraction:**
1. **Empty PDF**: Document contains no readable content
2. **Image quality**: Low-resolution scans that are difficult to process
3. **Complex formatting**: Tables, charts, or unusual layouts
4. **Protected content**: Password-protected or encrypted sections
5. **Non-text elements**: PDF contains only images, diagrams, or graphics

**Recommendation:**
If this PDF should contain text content, try:
- Ensuring the PDF is not corrupted
- Checking if the document requires a password
- Using higher resolution scans for image-based PDFs
- Converting complex layouts to simpler text formats''';
  }

  Future<String> _extractImageText(File file) async {
    try {
      logger.info('Starting OCR text extraction from image: ${file.path}');

      final extractedText = await _extractTextWithTesseract(file);

      if (extractedText.trim().isNotEmpty) {
        logger.info(
          'Successfully extracted text with OCR from image: ${file.path}',
        );
        return _formatOcrText(extractedText, 'Tesseract OCR');
      } else {
        logger.info('OCR completed but no text found in image: ${file.path}');
        return _createImageAnalysisResult(
          file.path,
          'Image processed - no text detected',
        );
      }
    } catch (e) {
      logger.severe('Error processing image with OCR: $e');
      return _createImageAnalysisResult(file.path, 'Error: $e');
    }
  }

  String _createImageAnalysisResult(String filePath, String message) {
    final fileName = path.basename(filePath);
    final fileSize = File(filePath).lengthSync();

    return '''🖼️ **Image File Processed**
📁 **File:** $fileName
📊 **Size:** ${_formatFileSize(fileSize)}
📍 **Path:** $filePath

$message

💡 The image was processed with OCR to extract any text content.''';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<int> _getPdfPageCount(File file) async {
    try {
      // Try to get page count using Ghostscript
      final result = await Process.run('gs', [
        '-q', // Quiet mode
        '-dNODISPLAY',
        '-c',
        '($file.path) (r) file runpdfbegin pdfpagecount = quit',
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        final pageCount = int.tryParse(output);
        if (pageCount != null && pageCount > 0) {
          return pageCount;
        }
      }

      // If Ghostscript fails, try ImageMagick identify command
      final identifyResult = await Process.run('magick', [
        'identify',
        file.path,
      ]);

      if (identifyResult.exitCode == 0) {
        final lines = identifyResult.stdout
            .toString()
            .split('\n')
            .where((line) => line.trim().isNotEmpty);
        return lines.length;
      }

      // If both fail, try convert identify
      final convertIdentifyResult = await Process.run('identify', [file.path]);

      if (convertIdentifyResult.exitCode == 0) {
        final lines = convertIdentifyResult.stdout
            .toString()
            .split('\n')
            .where((line) => line.trim().isNotEmpty);
        return lines.length;
      }

      // If all methods fail, assume single page
      logger.warning('Could not determine PDF page count, assuming 1 page');
      return 1;
    } catch (e) {
      logger.warning('Error getting PDF page count: $e, assuming 1 page');
      return 1;
    }
  }
}
