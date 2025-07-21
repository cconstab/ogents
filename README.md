# og## 📋 Features

- **📧 Email Monitoring**: Direct IMAP integration + directory monitoring for automated PDF processing
- **🔔 Notification-Based**: Triggers automatically when files are sent via atPlatform
- **📁 Multi-Format Support**: Handles text files, documents, archives, PDFs, and images
- **🧠 AI Summarization**: Integrates with LLM services (Ollama) for intelligent content analysis
- **🔒 Secure**: End-to-end encryption via atSign messaging
- **🌐 URL Support**: Can process files from URLs as well as local files
- **👁️ Advanced OCR**: Full multi-page PDF text extraction using Tesseract OCR
- **📊 Archive Support**: Automatically extracts and processes ZIP/TAR archives
- **⚡ Real-time**: Instant processing and response via atPlatform notifications
- **📨 IMAP Integration**: Connect to Gmail, Outlook, Yahoo, and custom email servers
- **🔍 Smart Processing**: Intelligent routing between OCR and LLM based on content typeAgent with atSign File Processing & Email Monitoring

An AI agent with an atSign that automatically processes file notifications and provides intelligent summaries using LLM services via the atPlatform. Now includes comprehensive email monitoring with IMAP support for automated PDF processing from email attachments.

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

The system consists of four main components:

1. **File Agent** (`ogents`): Receives file notifications, downloads files, and orchestrates the summarization process
2. **Email Monitor** (`email_monitor`): Monitors email accounts or directories for PDF attachments and auto-sends to ogents
3. **LLM Service** (`llm_service`): Provides text summarization capabilities using various LLM backends
4. **File Sender** (`send_file`): Utility to manually send files to the agent for processing

## Installation

### Prerequisites

- Dart SDK 3.8.1 or higher
- Active atSign (get one from [my.atsign.com](https://my.atsign.com))
- atSign keys properly configured
- **Tesseract OCR** and **ImageMagick** (required for PDF processing)
- **Ghostscript** (for advanced PDF operations)

### Installing OCR Dependencies

**macOS:**
```bash
# Install required OCR tools
brew install tesseract imagemagick ghostscript

# Verify installations
tesseract --version
magick --version
gs --version
```

**Linux (Ubuntu/Debian):**
```bash
# Install required OCR tools
sudo apt-get update
sudo apt-get install tesseract-ocr imagemagick ghostscript

# Verify installations
tesseract --version
convert --version
gs --version
```

### Building from Source

```bash
git clone https://github.com/cconstab/ogents.git
cd ogents
dart pub get
dart compile exe bin/ogents.dart -o ogents
dart compile exe bin/email_monitor.dart -o email_monitor
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

### 4. Email Monitoring (Optional)

Start email monitoring for automatic PDF processing from email attachments:

**Directory Mode** (Monitor local folder):
```bash
./email_monitor -a @your_atsign -g @agent_atsign -n ogents -e ./email_attachments -i 30
```

**IMAP Mode** (Connect to email account):
```bash
./email_monitor -a @your_atsign -g @agent_atsign -n ogents \
  --imap-server imap.gmail.com \
  --email your.email@gmail.com \
  --password your_app_password \
  --ssl
```

**Supported Email Providers:**
- **Gmail**: `imap.gmail.com` (requires App Password)
- **Outlook**: `outlook.office365.com`  
- **Yahoo**: `imap.mail.yahoo.com` (requires App Password)
- **Custom IMAP servers**: Any RFC-compliant IMAP server

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

### Full OCR Processing ✅
The system includes comprehensive OCR (Optical Character Recognition) using native tools:
- **Multi-page PDF Processing**: Handles PDFs up to 10 pages with complete text extraction
- **High-Quality Image Conversion**: 300 DPI conversion for optimal OCR accuracy
- **Intelligent Content Routing**: Automatically chooses between direct OCR return or LLM summarization
- **Image Text Recognition**: Processes JPG, PNG, BMP, TIFF, and GIF images
- **Multi-language Support**: Configurable language detection (default: English)
- **Robust Error Handling**: Graceful fallback and detailed error reporting

**Technical Stack**: 
- Tesseract OCR for text extraction
- ImageMagick for PDF-to-image conversion
- Ghostscript for PDF processing and page counting
- Native Dart implementation (no Rust required)

### Email Automation ✅
Complete email monitoring system for automated PDF processing:
- **IMAP Integration**: Direct connection to email accounts
- **Directory Monitoring**: Watch local folders for new PDFs  
- **Size Validation**: Automatic size checking (8MB limit) to prevent buffer overflow
- **File Archival**: Processed files moved to timestamped archive folders
- **Real-time Processing**: Immediate detection and processing of new PDFs

### Example Workflow

1. **Start LLM Service**:
   ```bash
   ./llm_service -a @llama -n ogents
   ```

2. **Start File Agent**:
   ```bash
   ./ogents -a @file_agent -l @llama -n ogents
   ```

3. **Start Email Monitoring** (optional):
   ```bash
   ./email_monitor -a @sender -g @file_agent -n ogents -e ./email_test -i 30
   ```

4. **Send a File**:
   ```bash
   ./send_file -a @alice -g @file_agent -f document.pdf -n ogents
   ```

5. **Email Processing**: Place PDFs in monitored directory or email folder, get automatic summaries

3. **Send a File**:
   ```bash
   ./send_file -a @alice -g @file_agent -f document.pdf -n ogents
   ```

4. **Receive Summary**: The sender will receive a detailed summary of the file content.

## Email Monitoring

The email monitor provides two modes for automated PDF processing:

### Directory Mode
Monitor a local directory for new PDF files:
```bash
./email_monitor -a @sender -g @agent -n ogents -e ./attachments -i 60
```

### IMAP Mode  
Connect directly to email accounts:
```bash
./email_monitor -a @sender -g @agent -n ogents \
  --imap-server imap.gmail.com \
  --email user@gmail.com \
  --password app_password \
  --folder INBOX \
  --ssl
```

**Features:**
- Automatic PDF attachment detection
- Size validation (max 8MB)
- Email marking as read after processing
- File archival with timestamps
- Support for all major email providers

## File Format Support

The agent can process various file formats:

- **Text Files**: `.txt`, `.md`, `.log`, `.csv`, `.json`, `.xml`, `.yaml`
- **PDF Documents**: `.pdf` (with advanced multi-page OCR text extraction up to 10 pages)
- **Archives**: `.zip`, `.tar`, `.gz` (extracts and processes text files within)
- **Images**: `.jpg`, `.png`, `.bmp`, `.tiff`, `.gif` (OCR text extraction)
- **Binary Files**: Basic analysis and metadata extraction
- **Large Files**: Automatic content truncation and size validation (8MB limit)

### Advanced PDF Processing

The system includes comprehensive PDF support with:
- **Multi-page OCR**: Process up to 10 pages per PDF with complete text extraction
- **High-resolution Conversion**: 300 DPI image conversion for optimal OCR accuracy
- **Smart Content Routing**: Single-page content returned directly, multi-page sent to LLM
- **Robust Error Handling**: Graceful fallback and detailed error reporting
- **Page Count Detection**: Automatic detection of PDF structure and page count
- **Memory Management**: Efficient processing with temporary file cleanup

**OCR Technical Stack:**
- Tesseract OCR engine for text extraction
- ImageMagick for PDF-to-image conversion  
- Ghostscript for PDF processing and validation
- Native Dart implementation with external tool integration

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
- `-v, --verbose`: Enable verbose logging

#### Email Monitor (`email_monitor`)
- `-a, --atsign`: Your atSign (sender)
- `-g, --agent`: atSign of the ogents file agent
- `-n, --namespace`: Namespace (default: ogents)
- `-e, --email-dir`: Directory to monitor (default: ./email_monitor)
- `-i, --poll-interval`: Check interval in seconds (default: 60)
- `--imap-server`: IMAP server hostname (e.g., imap.gmail.com)
- `--imap-port`: IMAP port (default: 993 for SSL, 143 for plain)
- `--email`: Email address for IMAP authentication
- `--password`: Password (use app passwords for Gmail/Yahoo)
- `--ssl`: Use SSL/TLS connection (default: true)
- `--folder`: Email folder to monitor (default: INBOX)

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
2. **Email Automation**: Automatically process PDF attachments from email accounts
3. **Code Review**: Get automated analysis of source code files
4. **Log Analysis**: Process log files for key insights and patterns
5. **Data Processing**: Analyze CSV files and data exports
6. **Archive Exploration**: Get overviews of compressed file contents
7. **Invoice Processing**: Monitor email for PDF invoices and auto-extract information
8. **Research Workflows**: Automatically summarize academic papers from email subscriptions

## Troubleshooting

### Connection Issues
- Ensure atSign keys are properly configured
- Check network connectivity
- Verify atSign is activated

### File Processing Issues
- Check file permissions and paths
- Verify supported file formats (8MB size limit)
- Monitor agent logs for detailed error messages
- For PDFs: Ensure Tesseract, ImageMagick, and Ghostscript are installed

### OCR Issues
- Verify OCR dependencies: `tesseract --version`, `magick --version`, `gs --version`
- Check PDF file integrity and format
- Monitor logs for OCR processing errors
- Large PDFs may be limited to first 10 pages

### Email Monitor Issues
- **IMAP Connection**: Verify server settings and credentials
- **Gmail**: Use App Passwords, not regular passwords
- **Directory Mode**: Check folder permissions and paths
- **Size Limits**: PDFs over 8MB will be rejected
- **Authentication**: Ensure proper atSign configuration

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
