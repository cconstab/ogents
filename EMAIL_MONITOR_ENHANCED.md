# Enhanced Email Monitor with IMAP Support

The email monitor now supports both **directory monitoring** and **IMAP email monitoring** for automatic PDF processing.

## Features

- 📁 **Directory Mode**: Monitor a local directory for PDF files
- 📧 **IMAP Mode**: Connect directly to email accounts and monitor for PDF attachments
- 🔄 **Automatic Processing**: PDFs are automatically sent to ogents for OCR and summarization
- 📦 **File Archival**: Processed files are moved to a `processed` subfolder
- 🔐 **Secure Communication**: Uses atPlatform for secure agent-to-agent communication

## Installation

Ensure you have the enhanced version compiled:

```bash
dart pub get
dart compile exe bin/email_monitor.dart -o email_monitor
```

## Usage

### Directory Mode (Original)

Monitor a local directory for PDF files:

```bash
./email_monitor \
  -a @your_atsign \
  -g @agent_atsign \
  -n ogents \
  -e ./email_attachments \
  -i 30
```

**Options:**
- `-e, --email-dir`: Directory to monitor for PDF files
- `-i, --poll-interval`: Check interval in seconds (default: 60)

### IMAP Mode (New!)

Connect directly to an email account:

```bash
./email_monitor \
  -a @your_atsign \
  -g @agent_atsign \
  -n ogents \
  --imap-server imap.gmail.com \
  --email your.email@gmail.com \
  --password your_app_password \
  --ssl \
  --folder INBOX \
  -i 60
```

**IMAP Options:**
- `--imap-server`: IMAP server hostname (e.g., imap.gmail.com)
- `--imap-port`: IMAP port (default: 993 for SSL, 143 for non-SSL)
- `--email`: Your email address
- `--password`: Your email password (use app passwords for Gmail)
- `--ssl`: Use SSL/TLS connection (default: true)
- `--folder`: Email folder to monitor (default: INBOX)

## Email Provider Examples

### Gmail
```bash
./email_monitor \
  -a @your_atsign \
  -g @agent_atsign \
  -n ogents \
  --imap-server imap.gmail.com \
  --email your.email@gmail.com \
  --password your_app_password \
  --ssl
```

**Note**: For Gmail, you must use an App Password, not your regular password:
1. Enable 2-factor authentication
2. Go to Google Account settings
3. Generate an App Password for "Mail"
4. Use this 16-character password

### Outlook/Hotmail
```bash
./email_monitor \
  -a @your_atsign \
  -g @agent_atsign \
  -n ogents \
  --imap-server outlook.office365.com \
  --email your.email@outlook.com \
  --password your_password \
  --ssl
```

### Yahoo Mail
```bash
./email_monitor \
  -a @your_atsign \
  -g @agent_atsign \
  -n ogents \
  --imap-server imap.mail.yahoo.com \
  --email your.email@yahoo.com \
  --password your_app_password \
  --ssl
```

### Custom IMAP Server
```bash
./email_monitor \
  -a @your_atsign \
  -g @agent_atsign \
  -n ogents \
  --imap-server mail.yourdomain.com \
  --imap-port 993 \
  --email user@yourdomain.com \
  --password your_password \
  --ssl
```

## How It Works

### Directory Mode
1. Monitor specified directory for new PDF files
2. When PDF detected, read file and encode as base64
3. Send to ogents agent via atPlatform notification
4. Wait for summary response
5. Display summary and move file to `processed/` subfolder

### IMAP Mode
1. Connect to IMAP server with provided credentials
2. Select specified folder (default: INBOX)
3. Check for new unread emails every poll interval
4. For each new email, scan for PDF attachments
5. Extract PDF data and send to ogents agent
6. Wait for summary response and display
7. Mark email as read

## Security Considerations

- **App Passwords**: Use app-specific passwords for Gmail and other providers
- **atPlatform**: All communication between agents is encrypted via atPlatform
- **Local Storage**: Email credentials are not stored permanently
- **Read-Only**: The system only reads emails and marks them as read

## Common IMAP Settings

| Provider | IMAP Server | Port | SSL | Notes |
|----------|-------------|------|-----|-------|
| Gmail | imap.gmail.com | 993 | Yes | Requires App Password |
| Outlook | outlook.office365.com | 993 | Yes | |
| Yahoo | imap.mail.yahoo.com | 993 | Yes | Requires App Password |
| Apple iCloud | imap.mail.me.com | 993 | Yes | Requires App Password |

## Troubleshooting

### IMAP Connection Issues
- Verify IMAP is enabled in your email provider settings
- Use app passwords for providers that require them
- Check firewall settings for outbound connections
- Try different port numbers (993 for SSL, 143 for plain)

### Authentication Errors
- Double-check email and password
- For Gmail: Ensure 2FA is enabled and you're using an App Password
- For corporate emails: Check with IT about IMAP access policies

### No PDFs Found
- Verify emails contain PDF attachments
- Check the folder name (case-sensitive)
- Monitor logs for processing errors
- Test with directory mode first to isolate issues

## Examples in Action

### Start IMAP monitoring for Gmail:
```bash
./email_monitor -a @alice -g @bob -n ogents --imap-server imap.gmail.com --email alice@gmail.com --password abcd1234efgh5678
```

### Start directory monitoring:
```bash
./email_monitor -a @alice -g @bob -n ogents -e ./email_test -i 30
```

The system will automatically detect which mode to use based on whether `--imap-server` is provided.

## Advanced Features

- **Multi-page PDFs**: Supports PDFs up to 10 pages with complete OCR processing
- **Smart Summarization**: Automatically routes content to LLM for intelligent summaries
- **Error Recovery**: Automatic reconnection on IMAP connection failures
- **Concurrent Processing**: Can handle multiple PDF attachments in a single email

## Integration with Email Clients

You can integrate this with various email setups:

1. **Email Rules**: Set up email rules to forward PDFs to a dedicated account
2. **Multiple Accounts**: Run multiple instances for different email accounts
3. **Webhook Integration**: Could be extended to work with email webhooks
4. **Server Deployment**: Run on a server for 24/7 monitoring

The enhanced email monitor provides a complete solution for automated PDF processing from both local files and live email streams.
