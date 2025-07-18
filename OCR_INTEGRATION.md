# OCR Integration Guide

## Overview
The ogents system currently supports basic PDF analysis but can be extended with OCR capabilities for extracting text from scanned PDFs and images.

## Why OCR Was Removed
The initial implementation used `tesseract_ocr` package, but this package has Flutter dependencies that are incompatible with command-line applications. The compilation failed with dart:ui dependency errors.

## OCR Implementation Options

### Option 1: External Tesseract Command (Recommended)
Use Tesseract directly via command-line execution:

```dart
Future<String> _extractTextWithOCR(String filePath) async {
  try {
    final result = await Process.run('tesseract', [filePath, 'stdout']);
    if (result.exitCode == 0) {
      return result.stdout as String;
    }
    return '';
  } catch (e) {
    print('OCR failed: $e');
    return '';
  }
}
```

### Option 2: Python Integration
Use Python's pytesseract via command execution:

```dart
Future<String> _extractTextWithPythonOCR(String filePath) async {
  final pythonScript = '''
import pytesseract
from PIL import Image
import sys

try:
    text = pytesseract.image_to_string(Image.open(sys.argv[1]))
    print(text)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
''';
  
  // Save script to temp file and execute
  final result = await Process.run('python3', ['-c', pythonScript, filePath]);
  return result.exitCode == 0 ? result.stdout as String : '';
}
```

### Option 3: HTTP API Service
Use an OCR service like Google Vision API or Azure Computer Vision:

```dart
Future<String> _extractTextWithAPI(String filePath) async {
  // Convert file to base64
  final bytes = await File(filePath).readAsBytes();
  final base64Image = base64Encode(bytes);
  
  // Send to OCR API (implementation depends on service)
  // Return extracted text
}
```

## Implementation Steps

1. **Choose OCR Method**: Select one of the options above based on your requirements.

2. **Update FileProcessor**: Add OCR method to `lib/src/file_processor.dart`:
   ```dart
   Future<String> _extractPdfText(File file) async {
     // Try OCR extraction
     final ocrText = await _extractTextWithOCR(file.path);
     if (ocrText.trim().isNotEmpty) {
       return _formatOcrText(ocrText, 'Tesseract OCR');
     }
     
     // Fall back to existing analysis
     return await _analyzePdfContent(file);
   }
   ```

3. **Handle Image Files**: Extend to support direct image OCR:
   ```dart
   bool _isImageFile(String fileName) {
     final ext = path.extension(fileName).toLowerCase();
     return ['.jpg', '.jpeg', '.png', '.bmp', '.tiff'].contains(ext);
   }
   ```

4. **Add Configuration**: Allow OCR to be enabled/disabled via environment variables.

## Prerequisites

### For Tesseract Command:
```bash
# macOS
brew install tesseract

# Ubuntu/Debian
sudo apt-get install tesseract-ocr

# Verify installation
tesseract --version
```

### For Python Integration:
```bash
pip install pytesseract pillow
```

## Testing OCR Integration

Create test files to verify OCR functionality:

```bash
# Test with a sample image
echo "Testing OCR..." | convert -pointsize 24 text:- test_image.png
tesseract test_image.png stdout
```

## Error Handling

Implement robust error handling for OCR operations:

```dart
Future<String> _safeOCR(String filePath) async {
  try {
    final ocrText = await _extractTextWithOCR(filePath);
    if (ocrText.trim().isEmpty) {
      logger.warning('OCR returned empty text for: $filePath');
      return 'OCR completed but no text was detected';
    }
    return ocrText;
  } catch (e) {
    logger.severe('OCR failed for $filePath: $e');
    return 'OCR processing failed: $e';
  }
}
```

## Future Enhancements

1. **Multi-language Support**: Configure Tesseract for specific languages
2. **Image Preprocessing**: Improve OCR accuracy with image enhancement
3. **Batch Processing**: Handle multiple pages/images efficiently
4. **OCR Confidence Scores**: Return accuracy metrics with extracted text

## Note

The current system provides excellent PDF analysis and text extraction for text-based PDFs. OCR is needed primarily for scanned documents and images. Consider the trade-offs between complexity and functionality when implementing OCR.
