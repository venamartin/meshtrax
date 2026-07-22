// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChannelMessageRowsTable extends ChannelMessageRows
    with TableInfo<$ChannelMessageRowsTable, ChannelMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelMessageRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nodeScopeMeta = const VerificationMeta(
    'nodeScope',
  );
  @override
  late final GeneratedColumn<String> nodeScope = GeneratedColumn<String>(
    'node_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdKeyMeta = const VerificationMeta(
    'channelIdKey',
  );
  @override
  late final GeneratedColumn<String> channelIdKey = GeneratedColumn<String>(
    'channel_id_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMsMeta = const VerificationMeta(
    'timestampMs',
  );
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
    'timestamp_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nodeScope,
    channelIdKey,
    messageId,
    timestampMs,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channel_message_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('node_scope')) {
      context.handle(
        _nodeScopeMeta,
        nodeScope.isAcceptableOrUnknown(data['node_scope']!, _nodeScopeMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeScopeMeta);
    }
    if (data.containsKey('channel_id_key')) {
      context.handle(
        _channelIdKeyMeta,
        channelIdKey.isAcceptableOrUnknown(
          data['channel_id_key']!,
          _channelIdKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_channelIdKeyMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('timestamp_ms')) {
      context.handle(
        _timestampMsMeta,
        timestampMs.isAcceptableOrUnknown(
          data['timestamp_ms']!,
          _timestampMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {nodeScope, channelIdKey, messageId},
  ];
  @override
  ChannelMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nodeScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_scope'],
      )!,
      channelIdKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id_key'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      timestampMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_ms'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $ChannelMessageRowsTable createAlias(String alias) {
    return $ChannelMessageRowsTable(attachedDatabase, alias);
  }
}

class ChannelMessageRow extends DataClass
    implements Insertable<ChannelMessageRow> {
  final int id;

  /// Scope: the connected node's pubkey prefix (one phone, many radios).
  final String nodeScope;

  /// Channel identity (Channel.idKey == pskHex) — never a slot index.
  final String channelIdKey;
  final String messageId;
  final int timestampMs;

  /// Remaining message fields as JSON. Keys live in real columns; promoting
  /// more fields to columns later is an additive migration.
  final String payload;
  const ChannelMessageRow({
    required this.id,
    required this.nodeScope,
    required this.channelIdKey,
    required this.messageId,
    required this.timestampMs,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['node_scope'] = Variable<String>(nodeScope);
    map['channel_id_key'] = Variable<String>(channelIdKey);
    map['message_id'] = Variable<String>(messageId);
    map['timestamp_ms'] = Variable<int>(timestampMs);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  ChannelMessageRowsCompanion toCompanion(bool nullToAbsent) {
    return ChannelMessageRowsCompanion(
      id: Value(id),
      nodeScope: Value(nodeScope),
      channelIdKey: Value(channelIdKey),
      messageId: Value(messageId),
      timestampMs: Value(timestampMs),
      payload: Value(payload),
    );
  }

  factory ChannelMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelMessageRow(
      id: serializer.fromJson<int>(json['id']),
      nodeScope: serializer.fromJson<String>(json['nodeScope']),
      channelIdKey: serializer.fromJson<String>(json['channelIdKey']),
      messageId: serializer.fromJson<String>(json['messageId']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nodeScope': serializer.toJson<String>(nodeScope),
      'channelIdKey': serializer.toJson<String>(channelIdKey),
      'messageId': serializer.toJson<String>(messageId),
      'timestampMs': serializer.toJson<int>(timestampMs),
      'payload': serializer.toJson<String>(payload),
    };
  }

  ChannelMessageRow copyWith({
    int? id,
    String? nodeScope,
    String? channelIdKey,
    String? messageId,
    int? timestampMs,
    String? payload,
  }) => ChannelMessageRow(
    id: id ?? this.id,
    nodeScope: nodeScope ?? this.nodeScope,
    channelIdKey: channelIdKey ?? this.channelIdKey,
    messageId: messageId ?? this.messageId,
    timestampMs: timestampMs ?? this.timestampMs,
    payload: payload ?? this.payload,
  );
  ChannelMessageRow copyWithCompanion(ChannelMessageRowsCompanion data) {
    return ChannelMessageRow(
      id: data.id.present ? data.id.value : this.id,
      nodeScope: data.nodeScope.present ? data.nodeScope.value : this.nodeScope,
      channelIdKey: data.channelIdKey.present
          ? data.channelIdKey.value
          : this.channelIdKey,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      timestampMs: data.timestampMs.present
          ? data.timestampMs.value
          : this.timestampMs,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelMessageRow(')
          ..write('id: $id, ')
          ..write('nodeScope: $nodeScope, ')
          ..write('channelIdKey: $channelIdKey, ')
          ..write('messageId: $messageId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nodeScope, channelIdKey, messageId, timestampMs, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelMessageRow &&
          other.id == this.id &&
          other.nodeScope == this.nodeScope &&
          other.channelIdKey == this.channelIdKey &&
          other.messageId == this.messageId &&
          other.timestampMs == this.timestampMs &&
          other.payload == this.payload);
}

class ChannelMessageRowsCompanion extends UpdateCompanion<ChannelMessageRow> {
  final Value<int> id;
  final Value<String> nodeScope;
  final Value<String> channelIdKey;
  final Value<String> messageId;
  final Value<int> timestampMs;
  final Value<String> payload;
  const ChannelMessageRowsCompanion({
    this.id = const Value.absent(),
    this.nodeScope = const Value.absent(),
    this.channelIdKey = const Value.absent(),
    this.messageId = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.payload = const Value.absent(),
  });
  ChannelMessageRowsCompanion.insert({
    this.id = const Value.absent(),
    required String nodeScope,
    required String channelIdKey,
    required String messageId,
    required int timestampMs,
    required String payload,
  }) : nodeScope = Value(nodeScope),
       channelIdKey = Value(channelIdKey),
       messageId = Value(messageId),
       timestampMs = Value(timestampMs),
       payload = Value(payload);
  static Insertable<ChannelMessageRow> custom({
    Expression<int>? id,
    Expression<String>? nodeScope,
    Expression<String>? channelIdKey,
    Expression<String>? messageId,
    Expression<int>? timestampMs,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeScope != null) 'node_scope': nodeScope,
      if (channelIdKey != null) 'channel_id_key': channelIdKey,
      if (messageId != null) 'message_id': messageId,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (payload != null) 'payload': payload,
    });
  }

  ChannelMessageRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? nodeScope,
    Value<String>? channelIdKey,
    Value<String>? messageId,
    Value<int>? timestampMs,
    Value<String>? payload,
  }) {
    return ChannelMessageRowsCompanion(
      id: id ?? this.id,
      nodeScope: nodeScope ?? this.nodeScope,
      channelIdKey: channelIdKey ?? this.channelIdKey,
      messageId: messageId ?? this.messageId,
      timestampMs: timestampMs ?? this.timestampMs,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nodeScope.present) {
      map['node_scope'] = Variable<String>(nodeScope.value);
    }
    if (channelIdKey.present) {
      map['channel_id_key'] = Variable<String>(channelIdKey.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelMessageRowsCompanion(')
          ..write('id: $id, ')
          ..write('nodeScope: $nodeScope, ')
          ..write('channelIdKey: $channelIdKey, ')
          ..write('messageId: $messageId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChannelMessageRowsTable channelMessageRows =
      $ChannelMessageRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [channelMessageRows];
}

typedef $$ChannelMessageRowsTableCreateCompanionBuilder =
    ChannelMessageRowsCompanion Function({
      Value<int> id,
      required String nodeScope,
      required String channelIdKey,
      required String messageId,
      required int timestampMs,
      required String payload,
    });
typedef $$ChannelMessageRowsTableUpdateCompanionBuilder =
    ChannelMessageRowsCompanion Function({
      Value<int> id,
      Value<String> nodeScope,
      Value<String> channelIdKey,
      Value<String> messageId,
      Value<int> timestampMs,
      Value<String> payload,
    });

class $$ChannelMessageRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelMessageRowsTable> {
  $$ChannelMessageRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelIdKey => $composableBuilder(
    column: $table.channelIdKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChannelMessageRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelMessageRowsTable> {
  $$ChannelMessageRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelIdKey => $composableBuilder(
    column: $table.channelIdKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelMessageRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelMessageRowsTable> {
  $$ChannelMessageRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nodeScope =>
      $composableBuilder(column: $table.nodeScope, builder: (column) => column);

  GeneratedColumn<String> get channelIdKey => $composableBuilder(
    column: $table.channelIdKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$ChannelMessageRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelMessageRowsTable,
          ChannelMessageRow,
          $$ChannelMessageRowsTableFilterComposer,
          $$ChannelMessageRowsTableOrderingComposer,
          $$ChannelMessageRowsTableAnnotationComposer,
          $$ChannelMessageRowsTableCreateCompanionBuilder,
          $$ChannelMessageRowsTableUpdateCompanionBuilder,
          (
            ChannelMessageRow,
            BaseReferences<
              _$AppDatabase,
              $ChannelMessageRowsTable,
              ChannelMessageRow
            >,
          ),
          ChannelMessageRow,
          PrefetchHooks Function()
        > {
  $$ChannelMessageRowsTableTableManager(
    _$AppDatabase db,
    $ChannelMessageRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelMessageRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelMessageRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelMessageRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nodeScope = const Value.absent(),
                Value<String> channelIdKey = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<int> timestampMs = const Value.absent(),
                Value<String> payload = const Value.absent(),
              }) => ChannelMessageRowsCompanion(
                id: id,
                nodeScope: nodeScope,
                channelIdKey: channelIdKey,
                messageId: messageId,
                timestampMs: timestampMs,
                payload: payload,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nodeScope,
                required String channelIdKey,
                required String messageId,
                required int timestampMs,
                required String payload,
              }) => ChannelMessageRowsCompanion.insert(
                id: id,
                nodeScope: nodeScope,
                channelIdKey: channelIdKey,
                messageId: messageId,
                timestampMs: timestampMs,
                payload: payload,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChannelMessageRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelMessageRowsTable,
      ChannelMessageRow,
      $$ChannelMessageRowsTableFilterComposer,
      $$ChannelMessageRowsTableOrderingComposer,
      $$ChannelMessageRowsTableAnnotationComposer,
      $$ChannelMessageRowsTableCreateCompanionBuilder,
      $$ChannelMessageRowsTableUpdateCompanionBuilder,
      (
        ChannelMessageRow,
        BaseReferences<
          _$AppDatabase,
          $ChannelMessageRowsTable,
          ChannelMessageRow
        >,
      ),
      ChannelMessageRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChannelMessageRowsTableTableManager get channelMessageRows =>
      $$ChannelMessageRowsTableTableManager(_db, _db.channelMessageRows);
}
