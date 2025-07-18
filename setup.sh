#!/bin/bash

# ogents Setup Script
# This script builds all the ogents components

echo "🚀 Setting up ogents - AI Agent with atSign File Processing"
echo ""

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "❌ Dart is not installed. Please install Dart SDK 3.8.1 or higher."
    echo "   Visit: https://dart.dev/get-dart"
    exit 1
fi

echo "✅ Dart found: $(dart --version)"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
dart pub get
if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo "✅ Dependencies installed"
echo ""

# Compile the main file agent
echo "🔨 Compiling File Agent..."
dart compile exe bin/ogents.dart -o ogents
if [ $? -ne 0 ]; then
    echo "❌ Failed to compile File Agent"
    exit 1
fi
echo "✅ File Agent compiled: ./ogents"

# Compile the LLM service
echo "🔨 Compiling LLM Service..."
dart compile exe bin/llm_service.dart -o llm_service
if [ $? -ne 0 ]; then
    echo "❌ Failed to compile LLM Service"
    exit 1
fi
echo "✅ LLM Service compiled: ./llm_service"

# Compile the file sender utility
echo "🔨 Compiling File Sender..."
dart compile exe bin/send_file.dart -o send_file
if [ $? -ne 0 ]; then
    echo "❌ Failed to compile File Sender"
    exit 1
fi
echo "✅ File Sender compiled: ./send_file"

echo ""
echo "🎉 Setup complete! All components have been built."
echo ""
echo "📚 Next steps:"
echo "1. Activate your atSign if you haven't already:"
echo "   dart run at_onboarding_cli -a @your_atsign"
echo ""
echo "2. Start the LLM service:"
echo "   ./llm_service -a @llm_service_atsign -n ogents"
echo ""
echo "3. Start the File Agent:"
echo "   ./ogents -a @agent_atsign -l @llm_service_atsign -n ogents"
echo ""
echo "4. Send a test file:"
echo "   ./send_file -a @your_atsign -g @agent_atsign -f examples/sample_document.md -n ogents"
echo ""
echo "📖 For more information, see README.md"
