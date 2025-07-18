#!/usr/bin/env dart

import 'dart:io';

/// Creates a simple test PDF for OCR testing
Future<void> main() async {
  // Create a simple text file that we can convert to PDF
  final testText =
      '''
Test Document for OCR Processing

This is a sample document created to test the PDF OCR functionality in the ogents system.

Key Features Being Tested:
- Text extraction from PDF documents
- OCR processing capabilities
- Integration with the atPlatform file sharing system

Sample Content:
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor 
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis 
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

Numbers and Special Characters:
- Date: ${DateTime.now()}
- Numbers: 1234567890
- Special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?

This document should be successfully processed by the OCR system and the text 
should be extracted for summarization by the LLM service.

End of Test Document
''';

  final testFile = File('test_document.txt');
  await testFile.writeAsString(testText);

  print('📄 Created test text file: ${testFile.path}');
  print('');
  print('📝 To create a PDF from this text:');
  print('   1. Open the text file in a text editor');
  print('   2. Print/Save as PDF, or');
  print('   3. Use online text-to-PDF converters, or');
  print('   4. Use pandoc: pandoc test_document.txt -o test_document.pdf');
  print('');
  print('🧪 To test OCR with a PDF file:');
  print('   dart test_pdf_ocr.dart your_file.pdf');
  print('');
  print('🚀 To test the full system:');
  print(
    '   1. Start the agent: ./ogents -a @your_agent -l @your_llm -n ogents',
  );
  print('   2. Send a PDF: ./send_file @your_agent test_document.pdf');
}
