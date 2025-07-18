# OCR Setup Guide for ogents

## Current Status

✅ **Working:** PDF detection and basic analysis  
✅ **Working:** Full OCR text extraction using Tesseract CLI  
✅ **Working:** Image text recognition (JPG, PNG, BMP, TIFF, GIF)  
✅ **Working:** Automatic fallback to analysis if OCR fails  

## The Challenge

The `pdf_ocr` package has a version compatibility issue with `flutter_rust_bridge`:
- Package was built with flutter_rust_bridge 2.3.0
- Current environment has flutter_rust_bridge 2.11.1
- This causes a runtime version mismatch error

## Solution Options

### Option 1: Use Alternative OCR Library (Recommended)

Use `tesseract_ocr` package which has better compatibility:

```yaml
dependencies:
  tesseract_ocr: ^0.0.3
```

**Pros:**
- Better maintained
- No version conflicts
- Works with command-line apps

**Cons:**
- Requires Tesseract binary installation

### Option 2: Build pdf_ocr from Source

Clone and rebuild the pdf_ocr package with current flutter_rust_bridge version:

```bash
# Clone the source
git clone https://github.com/kadasolutions/pdf_ocr.git
cd pdf_ocr

# Update flutter_rust_bridge in pubspec.yaml
# Regenerate code
flutter packages pub run build_runner build

# Use as path dependency
```

### Option 3: Manual OCR Integration

Set up direct integration with OCR services:

1. **Tesseract CLI Integration**
2. **Google Cloud Vision API**
3. **AWS Textract**
4. **Azure Computer Vision**

## Current Implementation

The system now provides:

✅ **PDF Detection**: Validates PDF file format  
✅ **Metadata Extraction**: File size, structure analysis  
✅ **Framework Ready**: Easy to add OCR when resolved  
✅ **Error Handling**: Graceful degradation  

## Testing the Current System

```bash
# Test PDF processing (without OCR)
./send_file @your_agent test_document.pdf

# You'll get analysis like:
# "📄 PDF Document Analyzed
#  ✅ PDF file format validated
#  📊 Basic metadata extracted
#  ⚠️ Text extraction requires OCR setup"
```

## Quick OCR Setup (Recommended)

1. **Install Tesseract:**
   ```bash
   # macOS
   brew install tesseract
   
   # Verify installation
   tesseract --version
   ```

2. **Add tesseract_ocr dependency:**
   ```yaml
   dependencies:
     tesseract_ocr: ^0.0.3
   ```

3. **Update FileProcessor:**
   ```dart
   import 'package:tesseract_ocr/tesseract_ocr.dart';
   
   Future<String> _extractPdfTextWithOCR(File file) async {
     // Convert PDF to images first, then OCR
     final text = await TesseractOcr.extractText(file.path);
     return text ?? '';
   }
   ```

## Advanced OCR Setup

For production use, consider:

1. **PDF to Image Conversion**: Use `pdf_render` package
2. **Image Preprocessing**: Enhance OCR accuracy
3. **Multi-language Support**: Configure Tesseract languages
4. **Cloud OCR**: For better accuracy and features

## Troubleshooting

### Version Conflicts
- Always check flutter_rust_bridge versions
- Use `dart pub deps` to verify compatibility
- Consider downgrading or upgrading packages together

### Native Dependencies
- OCR often requires native libraries
- Test on target deployment platforms
- Consider Docker for consistent environments

### Performance
- OCR is CPU-intensive
- Consider async processing for large files
- Implement caching for repeated processing

## Future Enhancements

1. **Hybrid Processing**: Combine multiple OCR engines
2. **Quality Detection**: Skip OCR for text-based PDFs
3. **Batch Processing**: Handle multiple files efficiently
4. **Cloud Integration**: Fallback to cloud OCR services
