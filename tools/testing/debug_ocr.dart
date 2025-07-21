#!/usr/bin/env dart

import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart debug_ocr.dart <file_path>');
    print('Example: dart debug_ocr.dart debug_test.png');
    exit(1);
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!file.existsSync()) {
    print('Error: File does not exist: $filePath');
    exit(1);
  }

  print('Testing OCR on file: $filePath');
  print('File size: ${file.lengthSync()} bytes');

  try {
    // Test direct Tesseract call
    print('\n=== Testing Tesseract directly ===');
    final result = await Process.run('tesseract', [
      file.path,
      'stdout',
      '-l',
      'eng',
    ]);

    print('Exit code: ${result.exitCode}');
    print('Stdout: "${result.stdout}"');
    print('Stderr: "${result.stderr}"');

    if (result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty) {
      print('\nOCR SUCCESS: Text extracted');
    } else {
      print('\nOCR FAILED: No text extracted or error occurred');
    }
  } catch (e) {
    print('Error during OCR processing: $e');
  }
}
