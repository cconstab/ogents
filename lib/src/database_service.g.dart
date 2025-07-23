// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_service.dart';

// ignore_for_file: type=lint
class $ProcessedFilesTable extends ProcessedFiles
    with TableInfo<$ProcessedFilesTable, ProcessedFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessedFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalDataMeta = const VerificationMeta(
    'originalData',
  );
  @override
  late final GeneratedColumn<Uint8List> originalData =
      GeneratedColumn<Uint8List>(
        'original_data',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<DateTime> processedAt = GeneratedColumn<DateTime>(
    'processed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _agentAtSignMeta = const VerificationMeta(
    'agentAtSign',
  );
  @override
  late final GeneratedColumn<String> agentAtSign = GeneratedColumn<String>(
    'agent_at_sign',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filename,
    originalData,
    summary,
    title,
    processedAt,
    sender,
    fileSize,
    fileType,
    ocrText,
    agentAtSign,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'processed_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessedFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('original_data')) {
      context.handle(
        _originalDataMeta,
        originalData.isAcceptableOrUnknown(
          data['original_data']!,
          _originalDataMeta,
        ),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processedAtMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    }
    if (data.containsKey('agent_at_sign')) {
      context.handle(
        _agentAtSignMeta,
        agentAtSign.isAcceptableOrUnknown(
          data['agent_at_sign']!,
          _agentAtSignMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessedFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessedFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      )!,
      originalData: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}original_data'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}processed_at'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      ),
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      ),
      agentAtSign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_at_sign'],
      ),
    );
  }

  @override
  $ProcessedFilesTable createAlias(String alias) {
    return $ProcessedFilesTable(attachedDatabase, alias);
  }
}

class ProcessedFile extends DataClass implements Insertable<ProcessedFile> {
  final String id;
  final String filename;
  final Uint8List? originalData;
  final String summary;
  final String? title;
  final DateTime processedAt;
  final String sender;
  final int? fileSize;
  final String? fileType;
  final String? ocrText;
  final String? agentAtSign;
  const ProcessedFile({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['filename'] = Variable<String>(filename);
    if (!nullToAbsent || originalData != null) {
      map['original_data'] = Variable<Uint8List>(originalData);
    }
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['processed_at'] = Variable<DateTime>(processedAt);
    map['sender'] = Variable<String>(sender);
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || fileType != null) {
      map['file_type'] = Variable<String>(fileType);
    }
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    if (!nullToAbsent || agentAtSign != null) {
      map['agent_at_sign'] = Variable<String>(agentAtSign);
    }
    return map;
  }

  ProcessedFilesCompanion toCompanion(bool nullToAbsent) {
    return ProcessedFilesCompanion(
      id: Value(id),
      filename: Value(filename),
      originalData: originalData == null && nullToAbsent
          ? const Value.absent()
          : Value(originalData),
      summary: Value(summary),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      processedAt: Value(processedAt),
      sender: Value(sender),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      fileType: fileType == null && nullToAbsent
          ? const Value.absent()
          : Value(fileType),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      agentAtSign: agentAtSign == null && nullToAbsent
          ? const Value.absent()
          : Value(agentAtSign),
    );
  }

  factory ProcessedFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessedFile(
      id: serializer.fromJson<String>(json['id']),
      filename: serializer.fromJson<String>(json['filename']),
      originalData: serializer.fromJson<Uint8List?>(json['originalData']),
      summary: serializer.fromJson<String>(json['summary']),
      title: serializer.fromJson<String?>(json['title']),
      processedAt: serializer.fromJson<DateTime>(json['processedAt']),
      sender: serializer.fromJson<String>(json['sender']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      fileType: serializer.fromJson<String?>(json['fileType']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      agentAtSign: serializer.fromJson<String?>(json['agentAtSign']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'filename': serializer.toJson<String>(filename),
      'originalData': serializer.toJson<Uint8List?>(originalData),
      'summary': serializer.toJson<String>(summary),
      'title': serializer.toJson<String?>(title),
      'processedAt': serializer.toJson<DateTime>(processedAt),
      'sender': serializer.toJson<String>(sender),
      'fileSize': serializer.toJson<int?>(fileSize),
      'fileType': serializer.toJson<String?>(fileType),
      'ocrText': serializer.toJson<String?>(ocrText),
      'agentAtSign': serializer.toJson<String?>(agentAtSign),
    };
  }

  ProcessedFile copyWith({
    String? id,
    String? filename,
    Value<Uint8List?> originalData = const Value.absent(),
    String? summary,
    Value<String?> title = const Value.absent(),
    DateTime? processedAt,
    String? sender,
    Value<int?> fileSize = const Value.absent(),
    Value<String?> fileType = const Value.absent(),
    Value<String?> ocrText = const Value.absent(),
    Value<String?> agentAtSign = const Value.absent(),
  }) => ProcessedFile(
    id: id ?? this.id,
    filename: filename ?? this.filename,
    originalData: originalData.present ? originalData.value : this.originalData,
    summary: summary ?? this.summary,
    title: title.present ? title.value : this.title,
    processedAt: processedAt ?? this.processedAt,
    sender: sender ?? this.sender,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    fileType: fileType.present ? fileType.value : this.fileType,
    ocrText: ocrText.present ? ocrText.value : this.ocrText,
    agentAtSign: agentAtSign.present ? agentAtSign.value : this.agentAtSign,
  );
  ProcessedFile copyWithCompanion(ProcessedFilesCompanion data) {
    return ProcessedFile(
      id: data.id.present ? data.id.value : this.id,
      filename: data.filename.present ? data.filename.value : this.filename,
      originalData: data.originalData.present
          ? data.originalData.value
          : this.originalData,
      summary: data.summary.present ? data.summary.value : this.summary,
      title: data.title.present ? data.title.value : this.title,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
      sender: data.sender.present ? data.sender.value : this.sender,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      agentAtSign: data.agentAtSign.present
          ? data.agentAtSign.value
          : this.agentAtSign,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessedFile(')
          ..write('id: $id, ')
          ..write('filename: $filename, ')
          ..write('originalData: $originalData, ')
          ..write('summary: $summary, ')
          ..write('title: $title, ')
          ..write('processedAt: $processedAt, ')
          ..write('sender: $sender, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileType: $fileType, ')
          ..write('ocrText: $ocrText, ')
          ..write('agentAtSign: $agentAtSign')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filename,
    $driftBlobEquality.hash(originalData),
    summary,
    title,
    processedAt,
    sender,
    fileSize,
    fileType,
    ocrText,
    agentAtSign,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessedFile &&
          other.id == this.id &&
          other.filename == this.filename &&
          $driftBlobEquality.equals(other.originalData, this.originalData) &&
          other.summary == this.summary &&
          other.title == this.title &&
          other.processedAt == this.processedAt &&
          other.sender == this.sender &&
          other.fileSize == this.fileSize &&
          other.fileType == this.fileType &&
          other.ocrText == this.ocrText &&
          other.agentAtSign == this.agentAtSign);
}

class ProcessedFilesCompanion extends UpdateCompanion<ProcessedFile> {
  final Value<String> id;
  final Value<String> filename;
  final Value<Uint8List?> originalData;
  final Value<String> summary;
  final Value<String?> title;
  final Value<DateTime> processedAt;
  final Value<String> sender;
  final Value<int?> fileSize;
  final Value<String?> fileType;
  final Value<String?> ocrText;
  final Value<String?> agentAtSign;
  final Value<int> rowid;
  const ProcessedFilesCompanion({
    this.id = const Value.absent(),
    this.filename = const Value.absent(),
    this.originalData = const Value.absent(),
    this.summary = const Value.absent(),
    this.title = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.sender = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileType = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.agentAtSign = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProcessedFilesCompanion.insert({
    required String id,
    required String filename,
    this.originalData = const Value.absent(),
    required String summary,
    this.title = const Value.absent(),
    required DateTime processedAt,
    required String sender,
    this.fileSize = const Value.absent(),
    this.fileType = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.agentAtSign = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       filename = Value(filename),
       summary = Value(summary),
       processedAt = Value(processedAt),
       sender = Value(sender);
  static Insertable<ProcessedFile> custom({
    Expression<String>? id,
    Expression<String>? filename,
    Expression<Uint8List>? originalData,
    Expression<String>? summary,
    Expression<String>? title,
    Expression<DateTime>? processedAt,
    Expression<String>? sender,
    Expression<int>? fileSize,
    Expression<String>? fileType,
    Expression<String>? ocrText,
    Expression<String>? agentAtSign,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filename != null) 'filename': filename,
      if (originalData != null) 'original_data': originalData,
      if (summary != null) 'summary': summary,
      if (title != null) 'title': title,
      if (processedAt != null) 'processed_at': processedAt,
      if (sender != null) 'sender': sender,
      if (fileSize != null) 'file_size': fileSize,
      if (fileType != null) 'file_type': fileType,
      if (ocrText != null) 'ocr_text': ocrText,
      if (agentAtSign != null) 'agent_at_sign': agentAtSign,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProcessedFilesCompanion copyWith({
    Value<String>? id,
    Value<String>? filename,
    Value<Uint8List?>? originalData,
    Value<String>? summary,
    Value<String?>? title,
    Value<DateTime>? processedAt,
    Value<String>? sender,
    Value<int?>? fileSize,
    Value<String?>? fileType,
    Value<String?>? ocrText,
    Value<String?>? agentAtSign,
    Value<int>? rowid,
  }) {
    return ProcessedFilesCompanion(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      originalData: originalData ?? this.originalData,
      summary: summary ?? this.summary,
      title: title ?? this.title,
      processedAt: processedAt ?? this.processedAt,
      sender: sender ?? this.sender,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      ocrText: ocrText ?? this.ocrText,
      agentAtSign: agentAtSign ?? this.agentAtSign,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (originalData.present) {
      map['original_data'] = Variable<Uint8List>(originalData.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<DateTime>(processedAt.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (agentAtSign.present) {
      map['agent_at_sign'] = Variable<String>(agentAtSign.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessedFilesCompanion(')
          ..write('id: $id, ')
          ..write('filename: $filename, ')
          ..write('originalData: $originalData, ')
          ..write('summary: $summary, ')
          ..write('title: $title, ')
          ..write('processedAt: $processedAt, ')
          ..write('sender: $sender, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileType: $fileType, ')
          ..write('ocrText: $ocrText, ')
          ..write('agentAtSign: $agentAtSign, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProcessedFilesTable processedFiles = $ProcessedFilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [processedFiles];
}

typedef $$ProcessedFilesTableCreateCompanionBuilder =
    ProcessedFilesCompanion Function({
      required String id,
      required String filename,
      Value<Uint8List?> originalData,
      required String summary,
      Value<String?> title,
      required DateTime processedAt,
      required String sender,
      Value<int?> fileSize,
      Value<String?> fileType,
      Value<String?> ocrText,
      Value<String?> agentAtSign,
      Value<int> rowid,
    });
typedef $$ProcessedFilesTableUpdateCompanionBuilder =
    ProcessedFilesCompanion Function({
      Value<String> id,
      Value<String> filename,
      Value<Uint8List?> originalData,
      Value<String> summary,
      Value<String?> title,
      Value<DateTime> processedAt,
      Value<String> sender,
      Value<int?> fileSize,
      Value<String?> fileType,
      Value<String?> ocrText,
      Value<String?> agentAtSign,
      Value<int> rowid,
    });

class $$ProcessedFilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProcessedFilesTable> {
  $$ProcessedFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get originalData => $composableBuilder(
    column: $table.originalData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentAtSign => $composableBuilder(
    column: $table.agentAtSign,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProcessedFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProcessedFilesTable> {
  $$ProcessedFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get originalData => $composableBuilder(
    column: $table.originalData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentAtSign => $composableBuilder(
    column: $table.agentAtSign,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProcessedFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProcessedFilesTable> {
  $$ProcessedFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<Uint8List> get originalData => $composableBuilder(
    column: $table.originalData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<String> get agentAtSign => $composableBuilder(
    column: $table.agentAtSign,
    builder: (column) => column,
  );
}

class $$ProcessedFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProcessedFilesTable,
          ProcessedFile,
          $$ProcessedFilesTableFilterComposer,
          $$ProcessedFilesTableOrderingComposer,
          $$ProcessedFilesTableAnnotationComposer,
          $$ProcessedFilesTableCreateCompanionBuilder,
          $$ProcessedFilesTableUpdateCompanionBuilder,
          (
            ProcessedFile,
            BaseReferences<_$AppDatabase, $ProcessedFilesTable, ProcessedFile>,
          ),
          ProcessedFile,
          PrefetchHooks Function()
        > {
  $$ProcessedFilesTableTableManager(
    _$AppDatabase db,
    $ProcessedFilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessedFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcessedFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcessedFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<Uint8List?> originalData = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<DateTime> processedAt = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> fileType = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String?> agentAtSign = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProcessedFilesCompanion(
                id: id,
                filename: filename,
                originalData: originalData,
                summary: summary,
                title: title,
                processedAt: processedAt,
                sender: sender,
                fileSize: fileSize,
                fileType: fileType,
                ocrText: ocrText,
                agentAtSign: agentAtSign,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String filename,
                Value<Uint8List?> originalData = const Value.absent(),
                required String summary,
                Value<String?> title = const Value.absent(),
                required DateTime processedAt,
                required String sender,
                Value<int?> fileSize = const Value.absent(),
                Value<String?> fileType = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String?> agentAtSign = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProcessedFilesCompanion.insert(
                id: id,
                filename: filename,
                originalData: originalData,
                summary: summary,
                title: title,
                processedAt: processedAt,
                sender: sender,
                fileSize: fileSize,
                fileType: fileType,
                ocrText: ocrText,
                agentAtSign: agentAtSign,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProcessedFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProcessedFilesTable,
      ProcessedFile,
      $$ProcessedFilesTableFilterComposer,
      $$ProcessedFilesTableOrderingComposer,
      $$ProcessedFilesTableAnnotationComposer,
      $$ProcessedFilesTableCreateCompanionBuilder,
      $$ProcessedFilesTableUpdateCompanionBuilder,
      (
        ProcessedFile,
        BaseReferences<_$AppDatabase, $ProcessedFilesTable, ProcessedFile>,
      ),
      ProcessedFile,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProcessedFilesTableTableManager get processedFiles =>
      $$ProcessedFilesTableTableManager(_db, _db.processedFiles);
}
