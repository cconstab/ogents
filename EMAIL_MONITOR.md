# Email PDF Monitor Agent

This agent monitors a directory for PDF files and automatically sends them to the ogents file processing agent for OCR and summarization.

## Features

- 📁 **Directory Monitoring**: Watches a specified directory for new PDF files
- 🔄 **Automatic Processing**: Automatically sends PDFs to ogents agent when detected
- 📧 **Email Integration Ready**: Designed to work with email clients that save attachments to folders
- 📦 **File Management**: Moves processed files to a "processed" subfolder
- 🔊 **Real-time Feedback**: Shows summaries as they're received
- ⏰ **Configurable Polling**: Adjustable check interval

## Quick Start

### 1. Start the ogents file agent
```bash
./ogents -a @your_atsign -l @llama -n ogents -v
```

### 2. Start the email monitor
```bash
./email_monitor -a @your_atsign -g @your_atsign -d ./email_pdfs
```

### 3. Drop PDF files
Place PDF files in the `./email_pdfs` directory and they'll be automatically processed!

## Command Line Options

```bash
./email_monitor [options]

Required:
  -a, --atsign          Your atSign for connecting to atPlatform
  -g, --agent           atSign of the ogents file agent

Optional:
  -d, --email-dir       Directory to monitor (default: ./email_monitor)
  -i, --poll-interval   Check interval in seconds (default: 60)
  -v, --verbose         Enable verbose logging
  -k, --key-file        Path to atSign keys file
```

## Usage Examples

### Basic monitoring
```bash
./email_monitor -a @alice -g @alice
```

### Custom directory and faster polling
```bash
./email_monitor -a @alice -g @alice -d /path/to/email/attachments -i 30
```

### With verbose logging
```bash
./email_monitor -a @alice -g @alice -v
```

## Email Client Integration

### Gmail (Desktop)
1. Set up a filter to save PDF attachments to a specific folder
2. Point the email monitor to that folder
3. PDFs will be automatically processed

### Outlook
1. Create a rule to save PDF attachments to a folder
2. Configure the monitor to watch that folder

### Thunderbird
1. Use the AttachmentExtractor add-on
2. Configure it to extract PDFs to a monitored directory

## Directory Structure

```
email_monitor_directory/
├── document1.pdf          # New files (will be processed)
├── document2.pdf
└── processed/             # Processed files (moved here)
    ├── 2025-07-19T15-30-00_document3.pdf
    └── 2025-07-19T15-31-00_document4.pdf
```

## What Happens

1. 📁 **File Detection**: Monitor finds new PDF files
2. 📤 **Send to ogents**: PDF is sent to the ogents agent via atPlatform
3. 🔍 **OCR Processing**: ogents performs multi-page OCR extraction
4. 🤖 **LLM Summarization**: Extracted text is sent to LLM for summary
5. 📋 **Display Results**: Summary is displayed in the monitor terminal
6. 📦 **File Archival**: Original PDF is moved to `processed/` folder

## Sample Output

```
Starting Email PDF Agent...
Email Directory: ./email_pdfs
Agent: @alice
Poll Interval: 60s
✅ Connected to atServer
📧 Starting email monitoring...
✅ Email agent is now running and monitoring for PDFs...

📧 Processing PDF file: contract.pdf
📤 Sending PDF "contract.pdf" to ogents agent...
✅ PDF "contract.pdf" sent to ogents agent successfully

📋 Summary received for "contract.pdf":
Agent: @alice
Time: 2025-07-19T15:30:00.000Z

--- SUMMARY ---
This is a comprehensive summary of a 5-page contract document...
The key terms include...
--- END SUMMARY ---

📦 Moved processed file to: ./email_pdfs/processed/2025-07-19T15-30-00_contract.pdf
```

## Integration with Email Systems

### For System Administrators
You can integrate this with email servers by:

1. **Procmail/Sieve filters** to extract PDF attachments
2. **IMAP folder monitoring** (future enhancement)
3. **Email forwarding rules** to a processing account
4. **Webhook integration** with email services

### For End Users
Simple workflow:
1. Forward emails with PDF attachments to a dedicated email address
2. Set up email client to auto-save attachments to monitored folder
3. Let the agent handle the rest automatically

## Troubleshooting

### No files being processed
- Check directory path is correct
- Ensure files are actual PDFs (not images named .pdf)
- Verify atSign connection with `-v` flag

### Summary not appearing
- Ensure ogents agent is running
- Check that both agents use the same atSign
- Verify network connectivity

### Permission errors
- Ensure write permissions to email directory
- Check that processed/ subfolder can be created

## Next Steps

Future enhancements could include:
- Direct IMAP email monitoring
- Database storage of summaries
- Web interface for summary viewing
- Email notification of processing results
- Multiple email account support
