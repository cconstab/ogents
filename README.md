# ogents - AI Agent with atSign File Processing

An AI agent with an atSign that automatically processes file notifications and provides summaries using LLM services via the atPlatform.

## 📋 Features

- **🔔 Notification-Based**: Triggers automatically when files are sent via atPlatform
- **📁 Multi-Format Support**: Handles text files, documents, archives, PDFs, and images
- **🧠 AI Summarization**: Integrates with LLM services (Ollama) for intelligent content analysis
- **🔒 Secure**: End-to-end encryption via atSign messaging
- **🌐 URL Support**: Can process files from URLs as well as local files
- **�️ OCR Capabilities**: Extracts text from PDFs and images using Tesseract OCR
- **📊 Archive Support**: Automatically extracts and processes ZIP/TAR archives
- **⚡ Real-time**: Instant processing and response via atPlatform notifications

## Architecture

The system consists of three main components:

1. **File Agent** (`ogents`): Receives file notifications, downloads files, and orchestrates the summarization process
2. **LLM Service** (`llm_service`): Provides text summarization capabilities using various LLM backends
3. **File Sender** (`send_file`): Utility to send files to the agent for processing

## Installation

### Prerequisites

- Dart SDK 3.8.1 or higher
- Active atSign (get one from [my.atsign.com](https://my.atsign.com))
- atSign keys properly configured
- **Rust toolchain** (required for PDF OCR functionality)

### Installing Rust for OCR Support

The PDF OCR functionality requires Rust. Install it using the provided script:

```bash
# Install Rust toolchain
./install_rust.sh

# Reload environment variables
source ~/.cargo/env

# Verify installation
rustc --version
cargo --version
```

### Building from Source

```bash
git clone https://github.com/cconstab/ogents.git
cd ogents
dart pub get
dart compile exe bin/ogents.dart -o ogents
dart compile exe bin/llm_service.dart -o llm_service
dart compile exe bin/send_file.dart -o send_file
```

## Setup

### 1. Activate your atSign

If you haven't activated your atSign yet:

```bash
dart run at_onboarding_cli -a @your_atsign
```

This will send you an OTP email. Enter the OTP to generate your atSign keys.

### 2. Start the LLM Service

First, start an LLM service that will handle summarization requests:

```bash
# Using simple rule-based summarizer
./llm_service -a @llm_service_atsign -n ogents

# Using Ollama (requires Ollama to be running)
./llm_service -a @llm_service_atsign -n ogents -t ollama --ollama-url http://localhost:11434 --ollama-model llama3.2
```

### 3. Start the File Agent

Start the main file agent:

```bash
./ogents -a @agent_atsign -l @llm_service_atsign -n ogents
```

The agent will start listening for file notifications and display:
```
✅ File agent is now running and listening for file notifications...
Send files to @agent_atsign using the key pattern: "file_share"
```

## Usage

### Sending Files for Processing

Use the `send_file` utility to send files or URLs to the agent:

**Send a local file:**
```bash
./send_file -a @your_atsign -g @agent_atsign -f /path/to/your/file.txt -n ogents
```

**Send a URL:**
```bash
./send_file -a @your_atsign -g @agent_atsign -u https://example.com/document.pdf -n ogents
```

The process will:
1. Send the file or URL to the agent
2. Agent downloads and processes the file (from local path or URL)
3. Agent sends the file content to the LLM service
4. LLM service returns a summary
5. Agent sends the summary back to you

## 🔧 Advanced Features

### OCR Capabilities ✅
The system now includes full OCR (Optical Character Recognition) functionality using Tesseract:
- **PDF Text Extraction**: Extracts text from scanned PDFs
- **Image Text Recognition**: Processes JPG, PNG, BMP, TIFF, and GIF images
- **Multi-language Support**: Configurable language detection (default: English)
- **Automatic Fallback**: Falls back to basic analysis if OCR fails

**Prerequisites**: Tesseract must be installed on your system:
```bash
# macOS
brew install tesseract

# Verify installation
tesseract --version
```

### Example Workflow

1. **Start LLM Service**:
   ```bash
   ./llm_service -a @llama -n ogents
   ```

2. **Start File Agent**:
   ```bash
   ./ogents -a @file_agent -l @llama -n ogents
   ```

3. **Send a File**:
   ```bash
   ./send_file -a @alice -g @file_agent -f document.pdf -n ogents
   ```

4. **Receive Summary**: The sender will receive a detailed summary of the file content.

## File Format Support

The agent can process various file formats:

- **Text Files**: `.txt`, `.md`, `.log`, `.csv`, `.json`, `.xml`, `.yaml`
- **PDF Documents**: `.pdf` (with advanced OCR text extraction)
- **Archives**: `.zip`, `.tar`, `.gz` (extracts and processes text files within)
- **Binary Files**: Basic analysis and metadata extraction
- **Large Files**: Automatic content truncation to prevent overwhelming the LLM

### PDF Processing with Analysis

The system includes comprehensive PDF support with:
- **PDF Detection**: Validates PDF file format and structure
- **Metadata Extraction**: File size, basic document information
- **Content Analysis**: Identifies document characteristics
- **OCR Framework**: Ready for OCR integration (see OCR_SETUP.md)

**Current PDF Features:**
- Native PDF format validation
- File structure analysis and metadata extraction
- Graceful handling of different PDF types
- Detailed processing feedback and status reporting
- Foundation for advanced OCR capabilities

**Testing PDF Processing:**
```bash
# Create a test document
dart create_test_pdf.dart

# Test PDF processing
dart test_pdf_processing.dart your_file.pdf

# Full OCR setup (optional)
# See OCR_SETUP.md for detailed instructions
```

**Current Implementation**: PDF files are detected and analyzed, providing detailed information about the document structure and processing recommendations.

## LLM Backend Options

### Simple Rule-Based Summarizer

The built-in summarizer provides:
- File statistics (lines, words, sentences)
- File type detection
- Key term extraction with frequency analysis
- Content preview
- No external dependencies

### Ollama Integration

Connect to local Ollama instance:
- Supports any Ollama model
- Full LLM-powered summarization
- Requires Ollama running locally

### Extending with Custom LLMs

Implement the `LLMProcessor` interface to add support for other LLM services:

```dart
abstract class LLMProcessor {
  Future<String> processPrompt(String prompt);
}
```

## Configuration

### Command Line Options

#### File Agent (`ogents`)
- `-a, --atsign`: Your atSign
- `-l, --llm-atsign`: atSign of the LLM service
- `-n, --namespace`: Namespace (default: ogents)
- `-p, --download-path`: Directory for downloads (default: ./downloads)

#### LLM Service (`llm_service`)
- `-a, --atsign`: LLM service atSign
- `-n, --namespace`: Namespace (default: ogents)
- `-t, --llm-type`: LLM type (simple, ollama)
- `--ollama-url`: Ollama API URL
- `--ollama-model`: Ollama model name

#### File Sender (`send_file`)
- `-a, --atsign`: Your atSign
- `-g, --agent`: Agent atSign
- `-f, --file`: Local file path to send (use either this or --url)
- `-u, --url`: URL of file to send (use either this or --file)
- `-n, --namespace`: Namespace

### Environment Variables

Standard atPlatform environment variables are supported:
- `AT_STORAGE_DIR`: Custom storage directory
- `AT_ROOT_DOMAIN`: Custom root domain

## Integration with ogentic

This project is designed to work with the [ogentic](https://github.com/cconstab/ogentic) chat application pattern. The LLM communication interface follows the same patterns used in ogentic for seamless integration.

## Security

- All file transfers are end-to-end encrypted via atPlatform
- File content is only shared between the specified atSigns
- No data is stored on intermediate servers
- LLM processing happens within your controlled environment

## Example Use Cases

1. **Document Analysis**: Send research papers, articles, or reports for quick summaries
2. **Code Review**: Get automated analysis of source code files
3. **Log Analysis**: Process log files for key insights and patterns
4. **Data Processing**: Analyze CSV files and data exports
5. **Archive Exploration**: Get overviews of compressed file contents

## Troubleshooting

### Connection Issues
- Ensure atSign keys are properly configured
- Check network connectivity
- Verify atSign is activated

### File Processing Issues
- Check file permissions and paths
- Verify supported file formats
- Monitor agent logs for detailed error messages

### LLM Service Issues
- Ensure LLM service is running and accessible
- Check namespace and atSign configuration
- For Ollama: verify Ollama is running and model is available

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bug reports and feature requests.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.

## Related Projects

- [atPlatform](https://docs.atsign.com) - The foundational platform for secure communications
- [ogentic](https://github.com/cconstab/ogentic) - Chat application with LLM integration
- [at_client_sdk](https://github.com/atsign-foundation/at_client_sdk) - Dart SDK for atPlatform
