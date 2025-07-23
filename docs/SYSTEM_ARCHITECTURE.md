# ogents System Architecture and Binary Guide

This document provides a comprehensive overview of all the binaries in the ogents system and how they work together.

## System Architecture

```mermaid
graph TB
    subgraph "Email Sources"
        EM[Email Accounts<br/>Gmail, Outlook, Yahoo]
        ED[Email Directory<br/>Local Folder]
    end
    
    subgraph "Monitoring Layer"
        EMO[email_monitor.dart<br/>Directory + IMAP Monitoring]
    end
    
    subgraph "Core Processing"
        FA[ogents.dart<br/>Main File Agent]
        FP[File Processor<br/>OCR, Archive, URL]
    end
    
    subgraph "AI Layer"
        LLM[llm_service.dart<br/>LLM Service Provider]
        OL[Ollama<br/>Local AI Models]
        SS[Simple Summarizer<br/>Built-in Rules]
    end
    
    subgraph "Web Interface"
        WF[web_frontend.dart<br/>Web Server + API]
        UI[Web UI<br/>Dashboard & Search]
        WS[WebSocket<br/>Real-time Updates]
    end
    
    subgraph "Data Layer"
        DB[(SQLite Database<br/>Drift ORM)]
        PS[ProcessedFiles Table<br/>Schema v2]
    end
    
    subgraph "Communication"
        AT[atPlatform<br/>Secure Messaging]
        SF[send_file.dart<br/>File Sender Utility]
    end
    
    subgraph "External Tools"
        TS[Tesseract OCR]
        IM[ImageMagick]
        GS[Ghostscript]
    end
    
    %% Data Flow
    EM --> EMO
    ED --> EMO
    EMO --> AT
    SF --> AT
    AT --> FA
    FA --> FP
    FP --> TS
    FP --> IM
    FP --> GS
    FA --> LLM
    LLM --> OL
    LLM --> SS
    LLM --> AT
    AT --> WF
    WF --> DB
    DB --> PS
    WF --> UI
    WF --> WS
    UI --> WS
    
    %% Styling
    classDef email fill:#e1f5fe
    classDef monitor fill:#f3e5f5
    classDef core fill:#e8f5e8
    classDef ai fill:#fff3e0
    classDef web fill:#e8eaf6
    classDef data fill:#f1f8e9
    classDef comm fill:#fce4ec
    classDef external fill:#fff8e1
    
    class EM,ED email
    class EMO monitor
    class FA,FP core
    class LLM,OL,SS ai
    class WF,UI,WS web
    class DB,PS data
    class AT,SF comm
    class TS,IM,GS external
```

## Binary Components

### 1. `ogents.dart` - Main File Agent
**Purpose**: Core file processing agent that handles atPlatform notifications
**Location**: `bin/ogents.dart`

**Functionality**:
- Listens for file notifications via atPlatform
- Processes various file formats (PDF, images, text, archives)
- Coordinates with LLM service for content analysis
- Handles OCR processing for images and PDFs
- Manages file downloads and URL processing

**Usage**:
```bash
dart run bin/ogents.dart -a @agent_atsign -l @llm_service_atsign -n ogents
```

**Key Arguments**:
- `-a, --atsign`: Your agent's atSign
- `-l, --llm-atsign`: atSign of the LLM service
- `-n, --namespace`: Namespace for communication (default: ogents)
- `-p, --download-path`: Directory for temporary file storage
- `-v, --verbose`: Enable detailed logging

**Dependencies**: File processor, atPlatform client, OCR tools

---

### 2. `email_monitor.dart` - Enhanced Email Monitor
**Purpose**: Advanced email monitoring with both IMAP and directory support
**Location**: `bin/email_monitor.dart`

**Functionality**:
- **IMAP Mode**: Direct connection to email accounts (Gmail, Outlook, Yahoo)
- **Directory Mode**: Monitors local folders for new PDF files
- Size validation (8MB limit) to prevent buffer overflow
- Automatic file archival with timestamps
- Email marking as read after processing
- Support for all major email providers

**Usage**:

**IMAP Mode**:
```bash
dart run bin/email_monitor.dart -a @sender -g @agent -n ogents \
  --imap-server imap.gmail.com \
  --email user@gmail.com \
  --password app_password \
  --ssl
```

**Directory Mode**:
```bash
dart run bin/email_monitor.dart -a @sender -g @agent -n ogents \
  -e ./email_attachments \
  -i 30
```

**Key Arguments**:
- `-a, --atsign`: Sender's atSign
- `-g, --agent`: Target ogents agent atSign
- `-e, --email-dir`: Directory to monitor (directory mode)
- `--imap-server`: IMAP server hostname
- `--email`: Email address for IMAP
- `--password`: Email password (use app passwords for Gmail/Yahoo)
- `--ssl`: Use SSL/TLS (default: true)
- `-i, --poll-interval`: Check interval in seconds

**Dependencies**: atPlatform client, enough_mail package for IMAP

---

### 3. `llm_service.dart` - LLM Service Provider
**Purpose**: AI-powered content analysis and summarization service
**Location**: `bin/llm_service.dart`

**Functionality**:
- **Ollama Integration**: Connects to local Ollama instances
- **Simple Summarizer**: Built-in rule-based analysis
- Processes text content and generates intelligent summaries
- Provides file statistics and key term extraction
- Supports multiple AI models through Ollama

**Usage**:

**With Ollama**:
```bash
dart run bin/llm_service.dart -a @llm_service -n ogents -t ollama \
  --ollama-url http://localhost:11434 \
  --ollama-model llama3.2
```

**Simple Mode**:
```bash
dart run bin/llm_service.dart -a @llm_service -n ogents -t simple
```

**Key Arguments**:
- `-a, --atsign`: LLM service atSign
- `-t, --llm-type`: Type of LLM (simple, ollama)
- `--ollama-url`: Ollama API URL
- `--ollama-model`: Ollama model name

**Dependencies**: Ollama (optional), atPlatform client

---

### 4. `send_file.dart` - File Sender Utility
**Purpose**: Command-line utility for sending files to ogents agents
**Location**: `bin/send_file.dart`

**Functionality**:
- Send local files to ogents agents
- Send URLs for remote file processing
- Direct integration with atPlatform messaging
- Support for all file types handled by ogents

**Usage**:

**Send Local File**:
```bash
dart run bin/send_file.dart -a @sender -g @agent -f /path/to/file.pdf -n ogents
```

**Send URL**:
```bash
dart run bin/send_file.dart -a @sender -g @agent -u https://example.com/doc.pdf -n ogents
```

**Key Arguments**:
- `-a, --atsign`: Sender's atSign
- `-g, --agent`: Target agent atSign
- `-f, --file`: Local file path
- `-u, --url`: URL to process
- `-n, --namespace`: Communication namespace

**Dependencies**: atPlatform client

---

### 5. `web_frontend.dart` - Web Dashboard & API Server
**Purpose**: Web-based dashboard for viewing and managing processed files
**Location**: `bin/web_frontend.dart`

**Functionality**:
- **Web Dashboard**: Modern UI for viewing processed documents
- **Real-time Updates**: WebSocket connections for live file notifications
- **Search & Filter**: Full-text search across document summaries and titles
- **Calendar View**: Timeline visualization of processed files
- **File Management**: Download originals, delete files, bulk cleanup
- **RESTful API**: Complete REST API for programmatic access
- **Auto-title Extraction**: AI-powered title generation from summaries
- **SQLite Database**: Persistent storage using Drift ORM

**Usage**:
```bash
dart run bin/web_frontend.dart -a @web_frontend -n ogents -p 8090
```

**Key Arguments**:
- `-a, --atsign`: Web frontend atSign
- `-n, --namespace`: Communication namespace
- `-p, --port`: Web server port (default: 8090)

**API Endpoints**:
- `GET /api/files` - List all processed files
- `GET /api/files/{id}` - Get specific file details
- `GET /api/files/{id}/download` - Download original file
- `GET /api/search?q={query}` - Search files by content
- `GET /api/calendar` - Get calendar view data
- `GET /api/stats` - System statistics
- `DELETE /api/files/{id}` - Delete specific file
- `DELETE /api/files/cleanup/{days}` - Cleanup files older than X days
- `POST /api/files/{id}/extract-title` - Extract title from summary

**Web Interface Features**:
- 📊 **Dashboard**: Overview of recent files and statistics
- 🔍 **Search**: Full-text search with highlighting
- 📅 **Calendar**: Visual timeline of document processing
- 📱 **Responsive**: Works on desktop, tablet, and mobile
- 🔄 **Real-time**: Live updates via WebSocket
- 📁 **File Management**: View, download, delete operations

**Dependencies**: Drift database, Shelf web server, atPlatform client

---

## Data Layer Architecture

### Database Schema (Drift ORM)
**Location**: `lib/src/database_service.dart`

**ProcessedFiles Table (Schema v2)**:
```sql
CREATE TABLE processed_files (
    id TEXT PRIMARY KEY,              -- UUID for each processed file
    filename TEXT NOT NULL,           -- Original filename
    original_data BLOB,               -- Binary file data (up to 8MB)
    summary TEXT NOT NULL,            -- AI-generated summary
    title TEXT,                       -- AI-extracted document title
    processed_at DATETIME NOT NULL,   -- Processing timestamp
    sender TEXT NOT NULL,             -- atSign of file sender
    file_size INTEGER,                -- File size in bytes
    file_type TEXT,                   -- Human-readable file type
    ocr_text TEXT,                    -- Raw OCR text (if applicable)
    agent_at_sign TEXT                -- Processing agent atSign
);
```

**Database Features**:
- **SQLite Backend**: Local file-based storage
- **Drift ORM**: Type-safe database operations
- **Auto-migration**: Schema versioning and upgrades
- **Full-text Search**: Search across summaries, titles, and OCR text
- **Date Indexing**: Efficient date-based queries for calendar view
- **Automatic Cleanup**: Configurable retention policies

**Generated Code**:
```bash
# Required for database functionality
dart run build_runner build
```

---

## System Workflow

### 1. Standard File Processing Flow
```
User → send_file.dart → atPlatform → ogents.dart → File Processor → LLM Service → Summary Response
```

### 2. Email Monitoring Flow
```
Email Account → email_monitor.dart → PDF Extraction → atPlatform → ogents.dart → OCR Processing → LLM Analysis → Summary
```

### 3. Web Frontend Integration Flow
```
File Processing → web_frontend_data notification → web_frontend.dart → Database Storage → WebSocket Broadcast → Web UI Update
```

### 4. Complete End-to-End Flow
```
Email/File → Monitor/Sender → atPlatform → ogents.dart → Processing → LLM Analysis → web_frontend.dart → Database → Web Dashboard
```

### 5. IMAP Email Flow
```
IMAP Server → email_monitor.dart → PDF Parsing → atPlatform → ogents.dart → Processing → Response → Web Frontend → Database
```

## File Processing Capabilities

### Supported Formats
- **PDFs**: Multi-page OCR processing (up to 10 pages)
- **Images**: JPG, PNG, BMP, TIFF, GIF with OCR
- **Text Files**: TXT, MD, LOG, CSV, JSON, XML, YAML
- **Archives**: ZIP, TAR, GZ (extracts and processes contents)
- **URLs**: Any web-accessible file

### OCR Technology Stack
- **Tesseract OCR**: Text extraction engine
- **ImageMagick**: PDF-to-image conversion (300 DPI)
- **Ghostscript**: PDF processing and page counting
- **Native Dart**: No Rust dependencies required

### Size Limits
- **Maximum File Size**: 8MB (prevents atPlatform buffer overflow)
- **PDF Page Limit**: 10 pages for OCR processing
- **Archive Processing**: Extracts and validates individual files

## Email Provider Configuration

### Gmail Setup
```bash
# IMAP Settings
Server: imap.gmail.com
Port: 993 (SSL)
Authentication: App Password required
```

### Outlook Setup
```bash
# IMAP Settings
Server: outlook.office365.com
Port: 993 (SSL)
Authentication: Regular password or app password
```

### Yahoo Setup
```bash
# IMAP Settings
Server: imap.mail.yahoo.com
Port: 993 (SSL)
Authentication: App Password required
```

## Development and Testing

### Testing Utilities Location
All testing utilities are located in `tools/testing/`:

- `create_test_pdf.dart`: Generate test PDF files
- `debug_ocr.dart`: OCR debugging and validation
- `test_file_processor.dart`: File processing tests
- `test_pdf_conversion.dart`: PDF conversion testing
- `verify_setup.dart`: System dependency verification

### Example Test Data
Sample files for testing are in `tools/testing/test_data/`:
- `PDF_TestPage.pdf`: Standard test PDF
- `test_document.pdf`: Multi-page test document

## Security Features

### atPlatform Security
- **End-to-End Encryption**: All communications encrypted
- **Authentication**: atSign-based identity verification
- **No Central Servers**: Decentralized architecture
- **Private Keys**: Local key storage and management

### File Handling Security
- **Size Validation**: Prevents buffer overflow attacks
- **Temporary Storage**: Automatic cleanup of processed files
- **Sandboxed Processing**: OCR tools run in isolated environment

## Error Handling and Monitoring

### Common Issues and Solutions

**Email Connection Issues**:
- Verify IMAP server settings
- Use app passwords for Gmail/Yahoo
- Check firewall and network settings

**OCR Processing Errors**:
- Ensure Tesseract, ImageMagick, and Ghostscript are installed
- Verify file permissions and temporary directory access
- Check file size limits (8MB maximum)

**atPlatform Communication Issues**:
- Verify atSign keys and authentication
- Check namespace configuration
- Ensure network connectivity to atPlatform servers

### Logging and Debugging
- Use `-v` or `--verbose` flags for detailed logging
- Check system logs for OCR tool errors
- Monitor file processing in download directories

## Performance Considerations

### Optimization Settings
- **Poll Intervals**: Adjust email checking frequency (default: 60s)
- **File Size Limits**: 8MB maximum to prevent memory issues
- **Concurrent Processing**: Single-threaded to ensure stability
- **Temporary Cleanup**: Automatic removal of processed files

### Resource Requirements
- **Memory**: 256MB minimum for basic operation
- **Storage**: Temporary space for file processing + SQLite database
- **Network**: Stable connection for atPlatform communication
- **CPU**: OCR processing is CPU-intensive for large PDFs

---

## atPlatform Notification System

### Notification Types and Flow

**1. `file_share` Notifications** (External → ogents.dart)
- **Source**: send_file.dart, email_monitor.dart
- **Target**: ogents.dart (main file agent)
- **Purpose**: Request file processing
- **Content**: File data, metadata, processing instructions

**2. `file_summary` Notifications** (ogents.dart → Original Sender)
- **Source**: ogents.dart
- **Target**: Original file sender
- **Purpose**: Return processing results to sender
- **Content**: Summary, statistics, processing status

**3. `web_frontend_data` Notifications** (ogents.dart → web_frontend.dart)
- **Source**: ogents.dart (main file agent)
- **Target**: web_frontend.dart
- **Purpose**: Store processed files in web database
- **Content**: Processed file data, summary, metadata for web dashboard

### Notification Namespace Structure
```
{notification_type}.{namespace}.{atsign}
```

**Examples**:
- `file_share.ogents.@agent` - File processing request
- `file_summary.ogents.@sender` - Processing result
- `web_frontend_data.ogents.@web_frontend` - Web dashboard data

### Component Communication Matrix

| From → To | Notification Type | Purpose |
|-----------|------------------|---------|
| send_file.dart → ogents.dart | `file_share` | File processing request |
| email_monitor.dart → ogents.dart | `file_share` | Email attachment processing |
| ogents.dart → Original Sender | `file_summary` | Processing results |
| ogents.dart → web_frontend.dart | `web_frontend_data` | Database storage |
| web_frontend.dart ↔ Web UI | WebSocket | Real-time updates |

---

## Integration Examples

### Complete System Setup
```bash
# 1. Generate database code (REQUIRED!)
dart run build_runner build

# 2. Start LLM Service
dart run bin/llm_service.dart -a @llm -n ogents -t ollama \
  --ollama-url http://localhost:11434 --ollama-model llama3.2

# 3. Start File Agent
dart run bin/ogents.dart -a @agent -l @llm -n ogents

# 4. Start Web Frontend (NEW!)
dart run bin/web_frontend.dart -a @web_frontend -n ogents -p 8090

# 5. Start Email Monitoring
dart run bin/email_monitor.dart -a @sender -g @agent -n ogents \
  --imap-server imap.gmail.com --email user@gmail.com --password app_pass --ssl

# 6. Send Test File
dart run bin/send_file.dart -a @user -g @agent -f document.pdf -n ogents

# 7. View Results
# Open http://localhost:8090 in your browser
```

### Web-Only Setup (File Processing + Dashboard)
```bash
# 1. Generate database code
dart run build_runner build

# 2. Start core services
dart run bin/llm_service.dart -a @llm -n ogents -t simple &
dart run bin/ogents.dart -a @agent -l @llm -n ogents &
dart run bin/web_frontend.dart -a @web_frontend -n ogents -p 8080 &

# 3. Send files via command line
dart run bin/send_file.dart -a @user -g @agent -f document.pdf -n ogents

# 4. View dashboard at http://localhost:8080
```

### Development Setup with Hot Reload
```bash
# Terminal 1: Database generation (run when schema changes)
dart run build_runner watch

# Terminal 2: LLM Service
dart run bin/llm_service.dart -a @llm -n ogents -t simple

# Terminal 3: File Agent with verbose logging  
dart run bin/ogents.dart -a @agent -l @llm -n ogents -v

# Terminal 4: Web Frontend with debug
dart run bin/web_frontend.dart -a @web_frontend -n ogents -p 8090 -v

# Terminal 5: Test file sending
dart run bin/send_file.dart -a @user -g @agent -f test.pdf -n ogents
```

This creates a complete automated document processing pipeline with email monitoring, OCR capabilities, AI-powered summarization, and a modern web dashboard for viewing and managing processed documents.

### Key System Features

**🔄 End-to-End Processing**:
- Email attachments automatically processed
- Files stored in SQLite database 
- Real-time web dashboard updates
- Full-text search capabilities

**🚀 Modern Architecture**:
- Microservices design with clear separation
- Event-driven communication via atPlatform
- RESTful API for integration
- WebSocket for real-time updates

**🔒 Security & Privacy**:
- End-to-end encryption via atPlatform
- Local data storage (no cloud dependency)
- Decentralized peer-to-peer architecture
- User-controlled data retention policies

**📊 Business Intelligence**:
- Document timeline visualization
- Processing statistics and analytics
- AI-powered title extraction
- Advanced search and filtering
