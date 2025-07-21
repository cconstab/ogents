import 'dart:io';

void main() async {
  // Test PDF file directly with the same logic used in FileProcessor
  final pdfFile = File(
    '/Users/cconstab/Documents/GitHub/cconstab/ogents/downloads/PDF_TestPage.pdf',
  );

  if (!pdfFile.existsSync()) {
    print('PDF file not found: ${pdfFile.path}');
    return;
  }

  print('Testing manual PDF extraction on: ${pdfFile.path}');
  print('File size: ${pdfFile.lengthSync()} bytes');

  // Simulate the same logic as in FileProcessor._extractPdfText
  final result = await _testExtractPdfText(pdfFile);

  print('\n=== RESULT ===');
  print(result);
  print('\n=== END RESULT ===');
}

Future<String> _testExtractPdfText(File file) async {
  try {
    print('Starting PDF text extraction with OCR: ${file.path}');

    // Check if it's actually a PDF file
    final bytes = await file.readAsBytes();
    if (!_isPdfFile(bytes)) {
      print('File is not a valid PDF: ${file.path}');
      return 'File is not a valid PDF format';
    }

    print('PDF validation passed');

    // Try OCR extraction (PDF -> Image -> OCR)
    final ocrContent = await _extractPdfTextWithImageConversion(file);

    if (ocrContent.trim().isNotEmpty) {
      print('Successfully extracted text with OCR from PDF: ${file.path}');
      return _formatOcrText(ocrContent, 'PDF-to-Image OCR');
    }

    print('OCR extraction failed or returned empty');
    return 'OCR extraction failed';
  } catch (e) {
    print('Error processing PDF: $e');
    return 'Error during processing: $e';
  }
}

Future<String> _extractPdfTextWithImageConversion(File file) async {
  Directory? tempDir;
  try {
    print('Converting PDF to images for OCR: ${file.path}');

    // Create temporary directory
    tempDir = await Directory.systemTemp.createTemp('pdf_ocr_');
    final tempImagePath = '${tempDir.path}/page.png';

    print('Temp directory created: ${tempDir.path}');
    print('Converting PDF page to: $tempImagePath');

    // Convert PDF first page to image using ImageMagick
    var convertResult = await Process.run('magick', [
      file.path + '[0]',
      '-density',
      '300',
      '-quality',
      '100',
      tempImagePath,
    ]);

    print('Magick command exit code: ${convertResult.exitCode}');
    print('Magick stdout: ${convertResult.stdout}');
    print('Magick stderr: ${convertResult.stderr}');

    if (convertResult.exitCode != 0) {
      print('Magick command failed, trying convert command...');
      convertResult = await Process.run('convert', [
        file.path + '[0]',
        '-density',
        '300',
        '-quality',
        '100',
        tempImagePath,
      ]);
    }

    if (convertResult.exitCode != 0) {
      print('ImageMagick conversion failed, trying Ghostscript...');
      convertResult = await Process.run('gs', [
        '-dNOPAUSE',
        '-dBATCH',
        '-sDEVICE=png16m',
        '-r300',
        '-dFirstPage=1',
        '-dLastPage=1',
        '-sOutputFile=$tempImagePath',
        file.path,
      ]);
    }

    if (convertResult.exitCode != 0) {
      print('PDF to image conversion failed: ${convertResult.stderr}');
      return '';
    }

    // Check if image was created
    final imageFile = File(tempImagePath);
    if (!imageFile.existsSync()) {
      print('Image file was not created during PDF conversion');
      return '';
    }

    print('Image created successfully, size: ${imageFile.lengthSync()} bytes');
    print('Running OCR on converted image...');

    // Run OCR on the converted image
    final ocrResult = await _extractTextWithTesseract(imageFile);

    print('OCR result length: ${ocrResult.length} characters');
    if (ocrResult.isNotEmpty) {
      print(
        'OCR preview: ${ocrResult.substring(0, ocrResult.length > 100 ? 100 : ocrResult.length)}...',
      );
    }

    return ocrResult;
  } catch (e) {
    print('Error in PDF to image OCR: $e');
    return '';
  } finally {
    // Clean up temporary directory
    if (tempDir != null) {
      try {
        await tempDir.delete(recursive: true);
        print('Cleaned up temporary OCR files');
      } catch (e) {
        print('Failed to clean up temp directory: $e');
      }
    }
  }
}

Future<String> _extractTextWithTesseract(File file) async {
  try {
    print('Attempting OCR text extraction using Tesseract CLI: ${file.path}');

    final result = await Process.run('tesseract', [
      file.path,
      'stdout',
      '-l',
      'eng',
    ]);

    if (result.exitCode == 0) {
      final extractedText = result.stdout as String;
      if (extractedText.trim().isNotEmpty) {
        print('Tesseract OCR successful for: ${file.path}');
        return extractedText.trim();
      } else {
        print('Tesseract OCR completed but no text found: ${file.path}');
        return '';
      }
    } else {
      final errorMessage = result.stderr as String;
      print(
        'Tesseract OCR failed with exit code ${result.exitCode}: $errorMessage',
      );
      return '';
    }
  } catch (e) {
    print('Error running Tesseract OCR: $e');
    return '';
  }
}

String _formatOcrText(String rawText, String method) {
  final cleanText = rawText
      .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'^\s+', multiLine: true), '')
      .trim();

  return '''📄 **PDF Text Content (Extracted with $method)**

$cleanText''';
}

bool _isPdfFile(List<int> bytes) {
  if (bytes.length < 5) return false;
  return bytes[0] == 0x25 && // %
      bytes[1] == 0x50 && // P
      bytes[2] == 0x44 && // D
      bytes[3] == 0x46 && // F
      bytes[4] == 0x2D; // -
}
