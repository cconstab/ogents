import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:at_utils/at_logger.dart';

part 'database_service.g.dart';

/// Table for storing processed files
class ProcessedFiles extends Table {
  TextColumn get id => text()();
  TextColumn get filename => text()();
  BlobColumn get originalData => blob().nullable()();
  TextColumn get summary => text()();
  TextColumn get title => text().nullable()(); // AI-extracted document title
  DateTimeColumn get processedAt => dateTime()();
  TextColumn get sender => text()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get fileType => text().nullable()();
  TextColumn get ocrText => text().nullable()();
  TextColumn get agentAtSign => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database for ogents web frontend
@DriftDatabase(tables: [ProcessedFiles])
class AppDatabase extends _$AppDatabase {
  final logger = AtSignLogger('Database');

  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // Incremented for title field

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      logger.info('Database created successfully');
    },
    onUpgrade: (Migrator m, int from, int to) async {
      logger.info('Database migrated from version $from to $to');
      if (from == 1 && to == 2) {
        // Add title column
        await m.addColumn(processedFiles, processedFiles.title);
        logger.info('Added title column to processedFiles table');
      }
    },
  );

  /// Insert a new processed file
  Future<void> insertProcessedFile(ProcessedFilesCompanion file) async {
    try {
      await into(processedFiles).insert(file);
      logger.info('Inserted file: ${file.filename.value}');
    } catch (e) {
      logger.severe('Failed to insert file: $e');
      rethrow;
    }
  }

  /// Get all processed files ordered by most recent first
  Future<List<ProcessedFile>> getAllProcessedFiles() async {
    try {
      final files = await (select(
        processedFiles,
      )..orderBy([(t) => OrderingTerm.desc(t.processedAt)])).get();
      logger.info('Retrieved ${files.length} files from database');
      return files;
    } catch (e) {
      logger.severe('Failed to get files: $e');
      rethrow;
    }
  }

  /// Get a specific file by ID
  Future<ProcessedFile?> getProcessedFileById(String id) async {
    try {
      final file = await (select(
        processedFiles,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      return file;
    } catch (e) {
      logger.severe('Failed to get file by ID: $e');
      rethrow;
    }
  }

  /// Check if a file already exists (to prevent duplicates)
  Future<bool> fileExists(String filename, String summary) async {
    try {
      final count =
          await (selectOnly(processedFiles)
                ..addColumns([processedFiles.id.count()])
                ..where(processedFiles.filename.equals(filename))
                ..where(processedFiles.summary.equals(summary)))
              .map((row) => row.read(processedFiles.id.count())!)
              .getSingle();

      return count > 0;
    } catch (e) {
      logger.severe('Failed to check file existence: $e');
      return false;
    }
  }

  /// Get total count of processed files
  Future<int> getFileCount() async {
    try {
      final count =
          await (selectOnly(processedFiles)
                ..addColumns([processedFiles.id.count()]))
              .map((row) => row.read(processedFiles.id.count())!)
              .getSingle();
      return count;
    } catch (e) {
      logger.severe('Failed to get file count: $e');
      return 0;
    }
  }

  /// Delete old files (keep only the most recent N files)
  Future<void> cleanupOldFiles({int keepCount = 100}) async {
    try {
      // Get files to delete (older than the keepCount most recent)
      final filesToDelete =
          await (select(processedFiles)
                ..orderBy([(t) => OrderingTerm.desc(t.processedAt)])
                ..limit(1000, offset: keepCount))
              .get();

      if (filesToDelete.isNotEmpty) {
        final idsToDelete = filesToDelete.map((f) => f.id).toList();
        await (delete(
          processedFiles,
        )..where((t) => t.id.isIn(idsToDelete))).go();

        logger.info('Deleted ${filesToDelete.length} old files');
      }
    } catch (e) {
      logger.severe('Failed to cleanup old files: $e');
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final totalFiles = await getFileCount();
      final oldestFile =
          await (select(processedFiles)
                ..orderBy([(t) => OrderingTerm.asc(t.processedAt)])
                ..limit(1))
              .getSingleOrNull();

      final newestFile =
          await (select(processedFiles)
                ..orderBy([(t) => OrderingTerm.desc(t.processedAt)])
                ..limit(1))
              .getSingleOrNull();

      return {
        'totalFiles': totalFiles,
        'oldestFile': oldestFile?.processedAt.toIso8601String(),
        'newestFile': newestFile?.processedAt.toIso8601String(),
      };
    } catch (e) {
      logger.severe('Failed to get database stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Search files by text in title, filename, or summary
  Future<List<ProcessedFile>> searchFiles(String query) async {
    try {
      final searchQuery = '%${query.toLowerCase()}%';
      final files =
          await (select(processedFiles)
                ..where(
                  (t) =>
                      t.title.lower().like(searchQuery) |
                      t.filename.lower().like(searchQuery) |
                      t.summary.lower().like(searchQuery),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.processedAt)]))
              .get();

      logger.info('Found ${files.length} files matching query: $query');
      return files;
    } catch (e) {
      logger.severe('Failed to search files: $e');
      rethrow;
    }
  }

  /// Get files for a specific date range
  Future<List<ProcessedFile>> getFilesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final files =
          await (select(processedFiles)
                ..where((t) => t.processedAt.isBetweenValues(start, end))
                ..orderBy([(t) => OrderingTerm.desc(t.processedAt)]))
              .get();

      logger.info('Found ${files.length} files between $start and $end');
      return files;
    } catch (e) {
      logger.severe('Failed to get files by date range: $e');
      rethrow;
    }
  }

  /// Get files grouped by date (for calendar view)
  Future<Map<String, List<ProcessedFile>>> getFilesGroupedByDate() async {
    try {
      final files = await getAllProcessedFiles();
      final groupedFiles = <String, List<ProcessedFile>>{};

      for (final file in files) {
        final dateKey =
            '${file.processedAt.year}-${file.processedAt.month.toString().padLeft(2, '0')}-${file.processedAt.day.toString().padLeft(2, '0')}';
        if (!groupedFiles.containsKey(dateKey)) {
          groupedFiles[dateKey] = [];
        }
        groupedFiles[dateKey]!.add(file);
      }

      logger.info(
        'Grouped ${files.length} files into ${groupedFiles.length} dates',
      );
      return groupedFiles;
    } catch (e) {
      logger.severe('Failed to group files by date: $e');
      rethrow;
    }
  }

  /// Delete a specific file by ID
  Future<bool> deleteFileById(String id) async {
    try {
      final deletedCount = await (delete(
        processedFiles,
      )..where((t) => t.id.equals(id))).go();

      logger.info('Deleted file with ID: $id');
      return deletedCount > 0;
    } catch (e) {
      logger.severe('Failed to delete file: $e');
      return false;
    }
  }

  /// Delete files older than a specific date
  Future<int> deleteFilesOlderThan(DateTime cutoffDate) async {
    try {
      final deletedCount = await (delete(
        processedFiles,
      )..where((t) => t.processedAt.isSmallerThanValue(cutoffDate))).go();

      logger.info('Deleted $deletedCount files older than $cutoffDate');
      return deletedCount;
    } catch (e) {
      logger.severe('Failed to delete old files: $e');
      return 0;
    }
  }

  /// Update file title (for LLM-extracted titles)
  Future<bool> updateFileTitle(String id, String title) async {
    try {
      final updatedCount =
          await (update(processedFiles)..where((t) => t.id.equals(id))).write(
            ProcessedFilesCompanion(title: Value(title)),
          );

      logger.info('Updated title for file ID: $id');
      return updatedCount > 0;
    } catch (e) {
      logger.severe('Failed to update file title: $e');
      return false;
    }
  }
}

/// Open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = Directory('.ogents_data');
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }

    final file = File(path.join(dbFolder.path, 'ogents.db'));
    return NativeDatabase(file);
  });
}

/// Helper class to convert between database and API models
class ProcessedFileModel {
  final String id;
  final String filename;
  final Uint8List? originalData;
  final String summary;
  final String? title; // AI-extracted document title
  final DateTime processedAt;
  final String sender;
  final int? fileSize;
  final String? fileType;
  final String? ocrText;
  final String? agentAtSign;

  ProcessedFileModel({
    required this.id,
    required this.filename,
    this.originalData,
    required this.summary,
    this.title,
    required this.processedAt,
    required this.sender,
    this.fileSize,
    this.fileType,
    this.ocrText,
    this.agentAtSign,
  });

  /// Convert from database model
  factory ProcessedFileModel.fromDb(ProcessedFile dbFile) {
    return ProcessedFileModel(
      id: dbFile.id,
      filename: dbFile.filename,
      originalData: dbFile.originalData,
      summary: dbFile.summary,
      title: dbFile.title,
      processedAt: dbFile.processedAt,
      sender: dbFile.sender,
      fileSize: dbFile.fileSize,
      fileType: dbFile.fileType,
      ocrText: dbFile.ocrText,
      agentAtSign: dbFile.agentAtSign,
    );
  }

  /// Convert to database companion for insertion
  ProcessedFilesCompanion toDbCompanion() {
    return ProcessedFilesCompanion(
      id: Value(id),
      filename: Value(filename),
      originalData: Value(originalData),
      summary: Value(summary),
      title: Value(title),
      processedAt: Value(processedAt),
      sender: Value(sender),
      fileSize: Value(fileSize),
      fileType: Value(fileType),
      ocrText: Value(ocrText),
      agentAtSign: Value(agentAtSign),
    );
  }

  /// Convert to JSON for API responses
  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'summary': summary,
    'title': title,
    'processedAt': processedAt.toIso8601String(),
    'sender': sender,
    'fileSize': fileSize,
    'fileType': fileType,
    'hasOriginalData': originalData != null,
    'ocrText': ocrText,
    'agentAtSign': agentAtSign,
  };
}
