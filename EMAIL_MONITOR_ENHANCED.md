# Complete Email Monitor Guide

The email monitor provides comprehensive email automation with both **directory monitoring** and **IMAP email monitoring** for automatic PDF processing.

## Quick Start

### 1. Build the Email Monitor
```bash
dart compile exe bin/email_monitor.dart -o email_monitor
```

### 2. Start the ogents File Agent
```bash
./ogents -a @agent_atsign -l @llm_atsign -n ogents -v
```

### 3. Choose Your Monitoring Mode

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

## Features

- 📁 **Directory Mode**: Monitor local folders for PDF files
- 📧 **IMAP Mode**: Direct email account integration
- 🔄 **Real-time Processing**: Automatic PDF detection and processing
- 📦 **File Management**: Automatic archival with timestamps
- 🔐 **Secure Communication**: End-to-end encryption via atPlatform
- 📏 **Size Validation**: 8MB limit with helpful error messages
- ⚡ **Performance**: Efficient polling with configurable intervals

## Email Provider Setup

### Gmail
```bash
./email_monitor -a @your_atsign -g @agent_atsign -n ogents \
  --imap-server imap.gmail.com \
  --email your.email@gmail.com \
  --password your_app_password \
  --ssl
```

**Gmail Requirements:**
1. Enable 2-factor authentication
2. Generate App Password: Google Account → Security → App passwords
3. Use the 16-character app password (not your regular password)

### Outlook/Microsoft 365
```bash
./email_monitor -a @your_atsign -g @agent_atsign -n ogents \
  --imap-server outlook.office365.com \
  --email your.email@outlook.com \
  --password your_password \
  --ssl
```

### Yahoo Mail
```bash
./email_monitor -a @your_atsign -g @agent_atsign -n ogents \
  --imap-server imap.mail.yahoo.com \
  --email your.email@yahoo.com \
  --password your_app_password \
  --ssl
```

**Yahoo Requirements:**
1. Enable 2-factor authentication  
2. Generate App Password: Account Security → Generate app password
3. Use the generated password

### Custom IMAP Server
```bash
./email_monitor -a @your_atsign -g @agent_atsign -n ogents \
  --imap-server mail.yourdomain.com \
  --imap-port 993 \
  --email user@yourdomain.com \
  --password your_password \
  --ssl
```

## Command Reference

### Required Options
- `-a, --atsign`: Your atSign (sender)
- `-g, --agent`: ogents file agent atSign  
- `-n, --namespace`: Namespace (typically "ogents")

### Directory Mode Options
- `-e, --email-dir`: Directory to monitor (default: ./email_monitor)
- `-i, --poll-interval`: Check interval in seconds (default: 60)

### IMAP Mode Options
- `--imap-server`: IMAP hostname (e.g., imap.gmail.com)
- `--imap-port`: IMAP port (993 for SSL, 143 for plain)
- `--email`: Email address for authentication
- `--password`: Email password (use app passwords)
- `--ssl`: Use SSL/TLS (default: true)
- `--folder`: Email folder to monitor (default: INBOX)

## How It Works

### Directory Mode Workflow
1. Monitor specified directory for new PDF files
2. When PDF detected, validate size (max 8MB)
3. Send to ogents agent via atPlatform notification
4. Wait for summary response and display
5. Move processed file to `processed/` subfolder with timestamp

### IMAP Mode Workflow
1. Connect to IMAP server with provided credentials
2. Select specified folder (default: INBOX)
3. Check for new unread emails every poll interval
4. Scan emails for PDF attachments
5. Validate attachment size and extract data
6. Send to ogents agent for processing
7. Display summary and mark email as read

## File Size Management

The system automatically handles file size limitations:

- **Maximum Size**: 8MB (atPlatform notification limit)
- **Size Display**: Shows file sizes in MB for visibility
- **Error Handling**: Helpful messages for oversized files
- **Suggestions**: Recommends using smaller PDFs or implementing chunking

**Example Output:**
```
📧 Processing PDF file: document.pdf (12.6MB)
❌ File too large: 12.6MB (max: 8MB)
💡 Consider using smaller PDFs or implement file chunking
```

## Integration Examples

### Email Rules Integration
Set up email rules to forward PDFs to a dedicated monitoring account:

1. **Gmail**: Settings → Filters → Forward PDFs to monitoring account
2. **Outlook**: Rules → Forward emails with PDF attachments
3. **Corporate**: IT can set server-side rules for department monitoring

### Multiple Account Monitoring
Run multiple instances for different email accounts:

```bash
# Personal email monitor
./email_monitor -a @alice -g @agent -n ogents --imap-server imap.gmail.com --email alice@gmail.com --password app1 &

# Work email monitor  
./email_monitor -a @alice_work -g @agent -n ogents --imap-server outlook.office365.com --email alice@company.com --password app2 &
```

### Production Deployment
For 24/7 monitoring, consider:

- **Systemd service** (Linux)
- **Cron job restart** (periodic restart)
- **Docker container** (containerized deployment)
- **Process monitoring** (PM2, supervisor)

## Troubleshooting

### IMAP Connection Issues
```
❌ Failed to connect to IMAP server
```
**Solutions:**
- Verify server hostname and port
- Check SSL/TLS settings
- Ensure firewall allows IMAP connections
- Test with email client (Thunderbird, Apple Mail)

### Authentication Errors
```
❌ IMAP authentication failed
```
**Solutions:**
- Use app passwords for Gmail/Yahoo (not regular passwords)
- Enable IMAP in email account settings
- Check username format (usually full email address)
- Verify 2FA is enabled for app password generation

### atPlatform Connection Issues
```
❌ Failed to initialize atClient
```
**Solutions:**
- Verify atSign keys are properly configured
- Check atSign activation status
- Ensure network connectivity to atPlatform
- Check atSign key file permissions

### File Processing Errors
```
❌ Error sending PDF to ogents
```
**Solutions:**
- Verify ogents agent is running
- Check agent atSign is correct
- Ensure namespace matches between services
- Check file size (must be under 8MB)

### No Emails Found
```
⚠️ No new emails found
```
**Possible Causes:**
- All emails already processed (check UID tracking)
- No unread emails in specified folder
- Folder name case sensitivity (use exact name)
- Email filters preventing delivery

## Security Considerations

### Email Security
- **App Passwords**: Never use regular email passwords
- **IMAP SSL**: Always use SSL/TLS encryption
- **Account Isolation**: Consider dedicated monitoring accounts
- **Credential Management**: Store passwords securely

### atPlatform Security
- **End-to-End Encryption**: All file transfers encrypted
- **Access Control**: Only specified atSigns can communicate
- **No Intermediate Storage**: Files processed in memory
- **Audit Trail**: Full logging of file transfers

### Network Security
- **Firewall**: Ensure IMAP ports (993/143) are accessible
- **VPN**: Consider VPN for corporate email access
- **DNS**: Verify IMAP server DNS resolution
- **Certificates**: Validate SSL certificates

## Performance Optimization

### Polling Intervals
- **Low Volume**: 300 seconds (5 minutes)
- **Medium Volume**: 60 seconds (1 minute)  
- **High Volume**: 30 seconds
- **Real-time**: 10 seconds (high resource usage)

### Resource Management
- **Memory**: Efficient PDF processing with cleanup
- **Network**: Optimized IMAP connection reuse
- **Storage**: Automatic processed file archival
- **CPU**: OCR processing is CPU-intensive

### Scaling Considerations
- **Multiple Instances**: Run separate instances per email account
- **Load Balancing**: Distribute across multiple servers
- **Database**: Consider database for large-scale UID tracking
- **Monitoring**: Implement health checks and alerts

This comprehensive email monitoring system provides enterprise-ready automation for PDF processing workflows with both flexibility and security.
