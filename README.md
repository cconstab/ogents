# ogents - AI Agent with atSign File Processing

An AI agent with an atSign that automatically processes file notifications and provides summaries using LLM services via the atPlatform.

## Features

- **File Reception**: Receives file notifications via atPlatform notifications
- **Automatic Download**: Downloads files from various sources (URLs, base64 data, atPlatform file transfer)
- **Content Extraction**: Extracts text content from multiple file formats (txt, md, json, xml, csv, archives, etc.)
- **LLM Integration**: Sends extracted content to LLM services for summarization
- **Secure Communication**: All communication happens via end-to-end encrypted atSign messaging
- **Flexible Architecture**: Supports multiple LLM backends (simple rule-based, Ollama, etc.)

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
- **Archives**: `.zip`, `.tar`, `.gz` (extracts and processes text files within)
- **Binary Files**: Basic analysis and metadata extraction
- **Large Files**: Automatic content truncation to prevent overwhelming the LLM

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
