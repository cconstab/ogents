# Quick Start Guide for ogents

This guide will help you get ogents up and running quickly for file processing and LLM summarization.

## Prerequisites

1. **Dart SDK 3.8.1+**: Install from [dart.dev](https://dart.dev/get-dart)
2. **atSign**: Get a free atSign from [my.atsign.com](https://my.atsign.com)
3. **Tesseract OCR**: For PDF/image text extraction: `brew install tesseract`
4. **Optional**: Ollama for advanced LLM capabilities

## Quick Setup

### 1. Build the Project

```bash
./setup.sh
```

This will install dependencies and compile all components.

### 2. Activate Your atSign

If you haven't activated your atSign yet:

```bash
dart run at_onboarding_cli -a @your_atsign
```

Follow the prompts to complete activation.

### 3. Start Services

**Terminal 1 - Start LLM Service:**
```bash
./llm_service -a @llm_service -n ogents
```

**Terminal 2 - Start File Agent:**
```bash
./ogents -a @file_agent -l @llm_service -n ogents
```

### 4. Test with Sample File

**Terminal 3 - Send a File:**
```bash
# Send a local file
./send_file -a @your_atsign -g @file_agent -f examples/sample_document.md -n ogents

# Or send a URL
./send_file -a @your_atsign -g @file_agent -u https://raw.githubusercontent.com/example/repo/main/README.md -n ogents
```

## Expected Output

1. **LLM Service** will show:
   ```
   🔍 Listening for LLM requests matching: llm_request.ogents@
   ```

2. **File Agent** will show:
   ```
   ✅ File agent is now running and listening for file notifications...
   Send files to @file_agent using the key pattern: "file_share"
   ```

3. **File Sender** will display the file summary once processed.

## Configuration Options

### Simple vs. Advanced LLM

**Simple (Default):**
- No external dependencies
- Rule-based text analysis
- Fast processing

**Ollama (Advanced):**
```bash
# Start Ollama first
ollama serve

# Then start LLM service with Ollama
./llm_service -a @llm_service -n ogents -t ollama --ollama-model llama3.2
```

### Custom Download Directory

```bash
./ogents -a @file_agent -l @llm_service -n ogents -p /custom/download/path
```

## File Format Support

✅ **Supported:**
- Text files (.txt, .md, .log)
- Data files (.csv, .json, .xml, .yaml)
- Archives (.zip, .tar, .gz)
- Code files (auto-detected)

⚠️ **Limited Support:**
- PDF files (basic info only)
- DOC/DOCX files (basic info only)
- Binary files (metadata only)

## Troubleshooting

### "Unable to connect to atServer"
- Check internet connection
- Verify atSign is activated
- Ensure correct atSign format (include @)

### "LLM service not responding"
- Confirm LLM service is running
- Check atSign configuration matches
- Verify namespace is consistent

### "File download failed"
- Check file permissions
- Verify file path is correct
- Ensure file size is reasonable

## Example Workflow

1. **Prepare**: Have three atSigns ready (@sender, @agent, @llm)
2. **Start**: Launch LLM service and file agent
3. **Send**: Use send_file utility to send documents
4. **Receive**: Get intelligent summaries back automatically

## Integration with Existing Systems

The ogents system can be integrated into existing workflows:

- **CI/CD**: Automatically analyze code commits
- **Document Management**: Process uploaded documents
- **Data Pipeline**: Analyze data files and logs
- **Research**: Summarize academic papers and reports

For more detailed information, see the main [README.md](README.md).
