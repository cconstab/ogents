#!/usr/bin/env dart

import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart test_pdf_conversion.dart <pdf_file_path>');
    exit(1);
  }

  final pdfPath = args[0];
  final pdfFile = File(pdfPath);

  if (!pdfFile.existsSync()) {
    print('Error: PDF file does not exist: $pdfPath');
    exit(1);
  }

  print('Testing PDF conversion for: $pdfPath');
  print('File size: ${pdfFile.lengthSync()} bytes');

  // Create temp directory
  final tempDir = await Directory.systemTemp.createTemp('pdf_test_');
  final tempImagePath = '${tempDir.path}/page.png';

  print('Temp directory: ${tempDir.path}');
  print('Target image: $tempImagePath');

  try {
    // Test 1: Try magick command
    print('\n=== Testing magick command ===');
    var result = await Process.run('magick', [
      pdfPath + '[0]',
      '-density',
      '300',
      '-quality',
      '100',
      tempImagePath,
    ]);

    print('Exit code: ${result.exitCode}');
    print('Stdout: ${result.stdout}');
    print('Stderr: ${result.stderr}');

    if (result.exitCode == 0 && File(tempImagePath).existsSync()) {
      print('✅ Magick conversion successful!');
      final imageSize = File(tempImagePath).lengthSync();
      print('Image size: $imageSize bytes');

      // Test OCR on the image
      print('\n=== Testing OCR ===');
      final ocrResult = await Process.run('tesseract', [
        tempImagePath,
        'stdout',
        '-l',
        'eng',
      ]);

      print('OCR Exit code: ${ocrResult.exitCode}');
      print('OCR Text: "${ocrResult.stdout}"');
      if (ocrResult.stderr.toString().isNotEmpty) {
        print('OCR Stderr: ${ocrResult.stderr}');
      }
    } else {
      print('❌ Magick conversion failed');

      // Try with convert
      if (File(tempImagePath).existsSync()) {
        await File(tempImagePath).delete();
      }

      print('\n=== Testing convert command ===');
      result = await Process.run('convert', [
        pdfPath + '[0]',
        '-density',
        '300',
        '-quality',
        '100',
        tempImagePath,
      ]);

      print('Exit code: ${result.exitCode}');
      print('Stdout: ${result.stdout}');
      print('Stderr: ${result.stderr}');

      if (result.exitCode == 0 && File(tempImagePath).existsSync()) {
        print('✅ Convert conversion successful!');
        final imageSize = File(tempImagePath).lengthSync();
        print('Image size: $imageSize bytes');
      } else {
        print('❌ Convert conversion failed');

        // Try Ghostscript
        if (File(tempImagePath).existsSync()) {
          await File(tempImagePath).delete();
        }

        print('\n=== Testing Ghostscript ===');
        result = await Process.run('gs', [
          '-dNOPAUSE',
          '-dBATCH',
          '-sDEVICE=png16m',
          '-r300',
          '-dFirstPage=1',
          '-dLastPage=1',
          '-sOutputFile=$tempImagePath',
          pdfPath,
        ]);

        print('Exit code: ${result.exitCode}');
        print('Stdout: ${result.stdout}');
        print('Stderr: ${result.stderr}');

        if (result.exitCode == 0 && File(tempImagePath).existsSync()) {
          print('✅ Ghostscript conversion successful!');
          final imageSize = File(tempImagePath).lengthSync();
          print('Image size: $imageSize bytes');
        } else {
          print('❌ All conversion methods failed');
        }
      }
    }
  } catch (e) {
    print('Error during testing: $e');
  } finally {
    // Cleanup
    try {
      await tempDir.delete(recursive: true);
      print('\nCleaned up temp directory');
    } catch (e) {
      print('Failed to cleanup: $e');
    }
  }
}
