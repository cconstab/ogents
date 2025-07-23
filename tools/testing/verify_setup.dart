#!/usr/bin/env dart

import 'dart:io';

/// Verification script to check if the system is properly set up for OCR
Future<void> main() async {
  print('🔍 **ogents PDF OCR System Verification**');
  print('═' * 50);

  // Check Dart
  print('📦 Checking Dart SDK...');
  try {
    final result = await Process.run('dart', ['--version']);
    if (result.exitCode == 0) {
      print('✅ Dart SDK: ${result.stdout.toString().trim()}');
    } else {
      print('❌ Dart SDK not found or error');
      exit(1);
    }
  } catch (e) {
    print('❌ Error checking Dart: $e');
    exit(1);
  }

  // Check Rust
  print('🦀 Checking Rust toolchain...');
  try {
    final result = await Process.run('rustc', ['--version']);
    if (result.exitCode == 0) {
      print('✅ Rust: ${result.stdout.toString().trim()}');
    } else {
      print('❌ Rust not found. Run: ./install_rust.sh');
      exit(1);
    }
  } catch (e) {
    print('❌ Rust not found. Run: ./install_rust.sh');
    exit(1);
  }

  // Check Cargo
  print('📦 Checking Cargo...');
  try {
    final result = await Process.run('cargo', ['--version']);
    if (result.exitCode == 0) {
      print('✅ Cargo: ${result.stdout.toString().trim()}');
    } else {
      print('❌ Cargo not found');
      exit(1);
    }
  } catch (e) {
    print('❌ Cargo not found');
    exit(1);
  }

  // Check compiled binaries
  print('🏗️  Checking compiled binaries...');
  final binaries = ['ogents', 'send_file', 'llm_service'];
  for (final binary in binaries) {
    final file = File(binary);
    if (file.existsSync()) {
      print('✅ $binary binary exists');
    } else {
      print(
        '⚠️  $binary binary not found (run: dart compile exe bin/$binary.dart -o $binary)',
      );
    }
  }

  // Check dependencies
  print('📚 Checking dependencies...');
  try {
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final content = await pubspecFile.readAsString();
      if (content.contains('pdf_ocr:')) {
        print('✅ pdf_ocr dependency found in pubspec.yaml');
      } else {
        print('❌ pdf_ocr dependency missing from pubspec.yaml');
      }
    }
  } catch (e) {
    print('❌ Error checking dependencies: $e');
  }

  print('');
  print('🎯 **Next Steps:**');
  if (Platform.environment['SHELL']?.contains('zsh') == true) {
    print('   1. If Rust was just installed, run: source ~/.cargo/env');
  }
  print('   2. Test PDF OCR: dart test_pdf_ocr.dart <your_pdf_file>');
  print('   3. Create test document: dart create_test_pdf.dart');
  print(
    '   4. Start the agent: ./ogents -a @your_agent -l @your_llm -n ogents',
  );
  print('   5. Send files: ./send_file @your_agent file.pdf');

  print('');
  print('✨ **OCR System Ready!**');
}
