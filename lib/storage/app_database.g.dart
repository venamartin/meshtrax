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
  static const VerificationMeta _packetHashMeta = const VerificationMeta(
    'packetHash',
  );
  @override
  late final GeneratedColumn<String> packetHash = GeneratedColumn<String>(
    'packet_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOutgoingMeta = const VerificationMeta(
    'isOutgoing',
  );
  @override
  late final GeneratedColumn<bool> isOutgoing = GeneratedColumn<bool>(
    'is_outgoing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_outgoing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unreadEligibleMeta = const VerificationMeta(
    'unreadEligible',
  );
  @override
  late final GeneratedColumn<bool> unreadEligible = GeneratedColumn<bool>(
    'unread_eligible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("unread_eligible" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    packetHash,
    isOutgoing,
    unreadEligible,
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
    if (data.containsKey('packet_hash')) {
      context.handle(
        _packetHashMeta,
        packetHash.isAcceptableOrUnknown(data['packet_hash']!, _packetHashMeta),
      );
    }
    if (data.containsKey('is_outgoing')) {
      context.handle(
        _isOutgoingMeta,
        isOutgoing.isAcceptableOrUnknown(data['is_outgoing']!, _isOutgoingMeta),
      );
    }
    if (data.containsKey('unread_eligible')) {
      context.handle(
        _unreadEligibleMeta,
        unreadEligible.isAcceptableOrUnknown(
          data['unread_eligible']!,
          _unreadEligibleMeta,
        ),
      );
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
      packetHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}packet_hash'],
      ),
      isOutgoing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_outgoing'],
      )!,
      unreadEligible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unread_eligible'],
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

  /// Firmware packet hash when known — repeat/echo dedup is a SQL lookup,
  /// not an in-memory scan (v3).
  final String? packetHash;

  /// Promoted so ordering/unread queries never parse JSON (v3).
  final bool isOutgoing;

  /// Decided ONCE at ingest: true only for messages that should count
  /// toward unread (not outgoing, not authored by this node) (v3).
  final bool unreadEligible;

  /// Remaining message fields as JSON. Keys live in real columns; promoting
  /// more fields to columns later is an additive migration.
  final String payload;
  const ChannelMessageRow({
    required this.id,
    required this.nodeScope,
    required this.channelIdKey,
    required this.messageId,
    required this.timestampMs,
    this.packetHash,
    required this.isOutgoing,
    required this.unreadEligible,
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
    if (!nullToAbsent || packetHash != null) {
      map['packet_hash'] = Variable<String>(packetHash);
    }
    map['is_outgoing'] = Variable<bool>(isOutgoing);
    map['unread_eligible'] = Variable<bool>(unreadEligible);
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
      packetHash: packetHash == null && nullToAbsent
          ? const Value.absent()
          : Value(packetHash),
      isOutgoing: Value(isOutgoing),
      unreadEligible: Value(unreadEligible),
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
      packetHash: serializer.fromJson<String?>(json['packetHash']),
      isOutgoing: serializer.fromJson<bool>(json['isOutgoing']),
      unreadEligible: serializer.fromJson<bool>(json['unreadEligible']),
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
      'packetHash': serializer.toJson<String?>(packetHash),
      'isOutgoing': serializer.toJson<bool>(isOutgoing),
      'unreadEligible': serializer.toJson<bool>(unreadEligible),
      'payload': serializer.toJson<String>(payload),
    };
  }

  ChannelMessageRow copyWith({
    int? id,
    String? nodeScope,
    String? channelIdKey,
    String? messageId,
    int? timestampMs,
    Value<String?> packetHash = const Value.absent(),
    bool? isOutgoing,
    bool? unreadEligible,
    String? payload,
  }) => ChannelMessageRow(
    id: id ?? this.id,
    nodeScope: nodeScope ?? this.nodeScope,
    channelIdKey: channelIdKey ?? this.channelIdKey,
    messageId: messageId ?? this.messageId,
    timestampMs: timestampMs ?? this.timestampMs,
    packetHash: packetHash.present ? packetHash.value : this.packetHash,
    isOutgoing: isOutgoing ?? this.isOutgoing,
    unreadEligible: unreadEligible ?? this.unreadEligible,
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
      packetHash: data.packetHash.present
          ? data.packetHash.value
          : this.packetHash,
      isOutgoing: data.isOutgoing.present
          ? data.isOutgoing.value
          : this.isOutgoing,
      unreadEligible: data.unreadEligible.present
          ? data.unreadEligible.value
          : this.unreadEligible,
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
          ..write('packetHash: $packetHash, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('unreadEligible: $unreadEligible, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nodeScope,
    channelIdKey,
    messageId,
    timestampMs,
    packetHash,
    isOutgoing,
    unreadEligible,
    payload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelMessageRow &&
          other.id == this.id &&
          other.nodeScope == this.nodeScope &&
          other.channelIdKey == this.channelIdKey &&
          other.messageId == this.messageId &&
          other.timestampMs == this.timestampMs &&
          other.packetHash == this.packetHash &&
          other.isOutgoing == this.isOutgoing &&
          other.unreadEligible == this.unreadEligible &&
          other.payload == this.payload);
}

class ChannelMessageRowsCompanion extends UpdateCompanion<ChannelMessageRow> {
  final Value<int> id;
  final Value<String> nodeScope;
  final Value<String> channelIdKey;
  final Value<String> messageId;
  final Value<int> timestampMs;
  final Value<String?> packetHash;
  final Value<bool> isOutgoing;
  final Value<bool> unreadEligible;
  final Value<String> payload;
  const ChannelMessageRowsCompanion({
    this.id = const Value.absent(),
    this.nodeScope = const Value.absent(),
    this.channelIdKey = const Value.absent(),
    this.messageId = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.packetHash = const Value.absent(),
    this.isOutgoing = const Value.absent(),
    this.unreadEligible = const Value.absent(),
    this.payload = const Value.absent(),
  });
  ChannelMessageRowsCompanion.insert({
    this.id = const Value.absent(),
    required String nodeScope,
    required String channelIdKey,
    required String messageId,
    required int timestampMs,
    this.packetHash = const Value.absent(),
    this.isOutgoing = const Value.absent(),
    this.unreadEligible = const Value.absent(),
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
    Expression<String>? packetHash,
    Expression<bool>? isOutgoing,
    Expression<bool>? unreadEligible,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeScope != null) 'node_scope': nodeScope,
      if (channelIdKey != null) 'channel_id_key': channelIdKey,
      if (messageId != null) 'message_id': messageId,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (packetHash != null) 'packet_hash': packetHash,
      if (isOutgoing != null) 'is_outgoing': isOutgoing,
      if (unreadEligible != null) 'unread_eligible': unreadEligible,
      if (payload != null) 'payload': payload,
    });
  }

  ChannelMessageRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? nodeScope,
    Value<String>? channelIdKey,
    Value<String>? messageId,
    Value<int>? timestampMs,
    Value<String?>? packetHash,
    Value<bool>? isOutgoing,
    Value<bool>? unreadEligible,
    Value<String>? payload,
  }) {
    return ChannelMessageRowsCompanion(
      id: id ?? this.id,
      nodeScope: nodeScope ?? this.nodeScope,
      channelIdKey: channelIdKey ?? this.channelIdKey,
      messageId: messageId ?? this.messageId,
      timestampMs: timestampMs ?? this.timestampMs,
      packetHash: packetHash ?? this.packetHash,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      unreadEligible: unreadEligible ?? this.unreadEligible,
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
    if (packetHash.present) {
      map['packet_hash'] = Variable<String>(packetHash.value);
    }
    if (isOutgoing.present) {
      map['is_outgoing'] = Variable<bool>(isOutgoing.value);
    }
    if (unreadEligible.present) {
      map['unread_eligible'] = Variable<bool>(unreadEligible.value);
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
          ..write('packetHash: $packetHash, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('unreadEligible: $unreadEligible, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

class $ContactMessageRowsTable extends ContactMessageRows
    with TableInfo<$ContactMessageRowsTable, ContactMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactMessageRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _contactKeyMeta = const VerificationMeta(
    'contactKey',
  );
  @override
  late final GeneratedColumn<String> contactKey = GeneratedColumn<String>(
    'contact_key',
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
  static const VerificationMeta _isOutgoingMeta = const VerificationMeta(
    'isOutgoing',
  );
  @override
  late final GeneratedColumn<bool> isOutgoing = GeneratedColumn<bool>(
    'is_outgoing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_outgoing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unreadEligibleMeta = const VerificationMeta(
    'unreadEligible',
  );
  @override
  late final GeneratedColumn<bool> unreadEligible = GeneratedColumn<bool>(
    'unread_eligible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("unread_eligible" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    contactKey,
    messageId,
    timestampMs,
    isOutgoing,
    unreadEligible,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_message_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactMessageRow> instance, {
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
    if (data.containsKey('contact_key')) {
      context.handle(
        _contactKeyMeta,
        contactKey.isAcceptableOrUnknown(data['contact_key']!, _contactKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_contactKeyMeta);
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
    if (data.containsKey('is_outgoing')) {
      context.handle(
        _isOutgoingMeta,
        isOutgoing.isAcceptableOrUnknown(data['is_outgoing']!, _isOutgoingMeta),
      );
    }
    if (data.containsKey('unread_eligible')) {
      context.handle(
        _unreadEligibleMeta,
        unreadEligible.isAcceptableOrUnknown(
          data['unread_eligible']!,
          _unreadEligibleMeta,
        ),
      );
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
    {nodeScope, contactKey, messageId},
  ];
  @override
  ContactMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nodeScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_scope'],
      )!,
      contactKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_key'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      timestampMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_ms'],
      )!,
      isOutgoing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_outgoing'],
      )!,
      unreadEligible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unread_eligible'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $ContactMessageRowsTable createAlias(String alias) {
    return $ContactMessageRowsTable(attachedDatabase, alias);
  }
}

class ContactMessageRow extends DataClass
    implements Insertable<ContactMessageRow> {
  final int id;

  /// Scope: the connected node's pubkey prefix (one phone, many radios).
  final String nodeScope;

  /// The other party's full pubkey hex — contacts' stable identity.
  final String contactKey;
  final String messageId;
  final int timestampMs;

  /// Promoted so unread/ordering queries never parse JSON (v4).
  final bool isOutgoing;

  /// Decided ONCE at ingest: counts toward unread only when not outgoing,
  /// not CLI traffic, and the contact tracks unread (v4).
  final bool unreadEligible;

  /// Remaining message fields as JSON; keys live in real columns.
  final String payload;
  const ContactMessageRow({
    required this.id,
    required this.nodeScope,
    required this.contactKey,
    required this.messageId,
    required this.timestampMs,
    required this.isOutgoing,
    required this.unreadEligible,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['node_scope'] = Variable<String>(nodeScope);
    map['contact_key'] = Variable<String>(contactKey);
    map['message_id'] = Variable<String>(messageId);
    map['timestamp_ms'] = Variable<int>(timestampMs);
    map['is_outgoing'] = Variable<bool>(isOutgoing);
    map['unread_eligible'] = Variable<bool>(unreadEligible);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  ContactMessageRowsCompanion toCompanion(bool nullToAbsent) {
    return ContactMessageRowsCompanion(
      id: Value(id),
      nodeScope: Value(nodeScope),
      contactKey: Value(contactKey),
      messageId: Value(messageId),
      timestampMs: Value(timestampMs),
      isOutgoing: Value(isOutgoing),
      unreadEligible: Value(unreadEligible),
      payload: Value(payload),
    );
  }

  factory ContactMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactMessageRow(
      id: serializer.fromJson<int>(json['id']),
      nodeScope: serializer.fromJson<String>(json['nodeScope']),
      contactKey: serializer.fromJson<String>(json['contactKey']),
      messageId: serializer.fromJson<String>(json['messageId']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
      isOutgoing: serializer.fromJson<bool>(json['isOutgoing']),
      unreadEligible: serializer.fromJson<bool>(json['unreadEligible']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nodeScope': serializer.toJson<String>(nodeScope),
      'contactKey': serializer.toJson<String>(contactKey),
      'messageId': serializer.toJson<String>(messageId),
      'timestampMs': serializer.toJson<int>(timestampMs),
      'isOutgoing': serializer.toJson<bool>(isOutgoing),
      'unreadEligible': serializer.toJson<bool>(unreadEligible),
      'payload': serializer.toJson<String>(payload),
    };
  }

  ContactMessageRow copyWith({
    int? id,
    String? nodeScope,
    String? contactKey,
    String? messageId,
    int? timestampMs,
    bool? isOutgoing,
    bool? unreadEligible,
    String? payload,
  }) => ContactMessageRow(
    id: id ?? this.id,
    nodeScope: nodeScope ?? this.nodeScope,
    contactKey: contactKey ?? this.contactKey,
    messageId: messageId ?? this.messageId,
    timestampMs: timestampMs ?? this.timestampMs,
    isOutgoing: isOutgoing ?? this.isOutgoing,
    unreadEligible: unreadEligible ?? this.unreadEligible,
    payload: payload ?? this.payload,
  );
  ContactMessageRow copyWithCompanion(ContactMessageRowsCompanion data) {
    return ContactMessageRow(
      id: data.id.present ? data.id.value : this.id,
      nodeScope: data.nodeScope.present ? data.nodeScope.value : this.nodeScope,
      contactKey: data.contactKey.present
          ? data.contactKey.value
          : this.contactKey,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      timestampMs: data.timestampMs.present
          ? data.timestampMs.value
          : this.timestampMs,
      isOutgoing: data.isOutgoing.present
          ? data.isOutgoing.value
          : this.isOutgoing,
      unreadEligible: data.unreadEligible.present
          ? data.unreadEligible.value
          : this.unreadEligible,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactMessageRow(')
          ..write('id: $id, ')
          ..write('nodeScope: $nodeScope, ')
          ..write('contactKey: $contactKey, ')
          ..write('messageId: $messageId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('unreadEligible: $unreadEligible, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nodeScope,
    contactKey,
    messageId,
    timestampMs,
    isOutgoing,
    unreadEligible,
    payload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactMessageRow &&
          other.id == this.id &&
          other.nodeScope == this.nodeScope &&
          other.contactKey == this.contactKey &&
          other.messageId == this.messageId &&
          other.timestampMs == this.timestampMs &&
          other.isOutgoing == this.isOutgoing &&
          other.unreadEligible == this.unreadEligible &&
          other.payload == this.payload);
}

class ContactMessageRowsCompanion extends UpdateCompanion<ContactMessageRow> {
  final Value<int> id;
  final Value<String> nodeScope;
  final Value<String> contactKey;
  final Value<String> messageId;
  final Value<int> timestampMs;
  final Value<bool> isOutgoing;
  final Value<bool> unreadEligible;
  final Value<String> payload;
  const ContactMessageRowsCompanion({
    this.id = const Value.absent(),
    this.nodeScope = const Value.absent(),
    this.contactKey = const Value.absent(),
    this.messageId = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.isOutgoing = const Value.absent(),
    this.unreadEligible = const Value.absent(),
    this.payload = const Value.absent(),
  });
  ContactMessageRowsCompanion.insert({
    this.id = const Value.absent(),
    required String nodeScope,
    required String contactKey,
    required String messageId,
    required int timestampMs,
    this.isOutgoing = const Value.absent(),
    this.unreadEligible = const Value.absent(),
    required String payload,
  }) : nodeScope = Value(nodeScope),
       contactKey = Value(contactKey),
       messageId = Value(messageId),
       timestampMs = Value(timestampMs),
       payload = Value(payload);
  static Insertable<ContactMessageRow> custom({
    Expression<int>? id,
    Expression<String>? nodeScope,
    Expression<String>? contactKey,
    Expression<String>? messageId,
    Expression<int>? timestampMs,
    Expression<bool>? isOutgoing,
    Expression<bool>? unreadEligible,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeScope != null) 'node_scope': nodeScope,
      if (contactKey != null) 'contact_key': contactKey,
      if (messageId != null) 'message_id': messageId,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (isOutgoing != null) 'is_outgoing': isOutgoing,
      if (unreadEligible != null) 'unread_eligible': unreadEligible,
      if (payload != null) 'payload': payload,
    });
  }

  ContactMessageRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? nodeScope,
    Value<String>? contactKey,
    Value<String>? messageId,
    Value<int>? timestampMs,
    Value<bool>? isOutgoing,
    Value<bool>? unreadEligible,
    Value<String>? payload,
  }) {
    return ContactMessageRowsCompanion(
      id: id ?? this.id,
      nodeScope: nodeScope ?? this.nodeScope,
      contactKey: contactKey ?? this.contactKey,
      messageId: messageId ?? this.messageId,
      timestampMs: timestampMs ?? this.timestampMs,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      unreadEligible: unreadEligible ?? this.unreadEligible,
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
    if (contactKey.present) {
      map['contact_key'] = Variable<String>(contactKey.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (isOutgoing.present) {
      map['is_outgoing'] = Variable<bool>(isOutgoing.value);
    }
    if (unreadEligible.present) {
      map['unread_eligible'] = Variable<bool>(unreadEligible.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactMessageRowsCompanion(')
          ..write('id: $id, ')
          ..write('nodeScope: $nodeScope, ')
          ..write('contactKey: $contactKey, ')
          ..write('messageId: $messageId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('unreadEligible: $unreadEligible, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

class $ChannelReadMarksTable extends ChannelReadMarks
    with TableInfo<$ChannelReadMarksTable, ChannelReadMark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelReadMarksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _idKeyMeta = const VerificationMeta('idKey');
  @override
  late final GeneratedColumn<String> idKey = GeneratedColumn<String>(
    'id_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReadMsMeta = const VerificationMeta(
    'lastReadMs',
  );
  @override
  late final GeneratedColumn<int> lastReadMs = GeneratedColumn<int>(
    'last_read_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [nodeScope, idKey, lastReadMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channel_read_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelReadMark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_scope')) {
      context.handle(
        _nodeScopeMeta,
        nodeScope.isAcceptableOrUnknown(data['node_scope']!, _nodeScopeMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeScopeMeta);
    }
    if (data.containsKey('id_key')) {
      context.handle(
        _idKeyMeta,
        idKey.isAcceptableOrUnknown(data['id_key']!, _idKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_idKeyMeta);
    }
    if (data.containsKey('last_read_ms')) {
      context.handle(
        _lastReadMsMeta,
        lastReadMs.isAcceptableOrUnknown(
          data['last_read_ms']!,
          _lastReadMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nodeScope, idKey};
  @override
  ChannelReadMark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelReadMark(
      nodeScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_scope'],
      )!,
      idKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_key'],
      )!,
      lastReadMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_ms'],
      )!,
    );
  }

  @override
  $ChannelReadMarksTable createAlias(String alias) {
    return $ChannelReadMarksTable(attachedDatabase, alias);
  }
}

class ChannelReadMark extends DataClass implements Insertable<ChannelReadMark> {
  final String nodeScope;
  final String idKey;
  final int lastReadMs;
  const ChannelReadMark({
    required this.nodeScope,
    required this.idKey,
    required this.lastReadMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_scope'] = Variable<String>(nodeScope);
    map['id_key'] = Variable<String>(idKey);
    map['last_read_ms'] = Variable<int>(lastReadMs);
    return map;
  }

  ChannelReadMarksCompanion toCompanion(bool nullToAbsent) {
    return ChannelReadMarksCompanion(
      nodeScope: Value(nodeScope),
      idKey: Value(idKey),
      lastReadMs: Value(lastReadMs),
    );
  }

  factory ChannelReadMark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelReadMark(
      nodeScope: serializer.fromJson<String>(json['nodeScope']),
      idKey: serializer.fromJson<String>(json['idKey']),
      lastReadMs: serializer.fromJson<int>(json['lastReadMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeScope': serializer.toJson<String>(nodeScope),
      'idKey': serializer.toJson<String>(idKey),
      'lastReadMs': serializer.toJson<int>(lastReadMs),
    };
  }

  ChannelReadMark copyWith({
    String? nodeScope,
    String? idKey,
    int? lastReadMs,
  }) => ChannelReadMark(
    nodeScope: nodeScope ?? this.nodeScope,
    idKey: idKey ?? this.idKey,
    lastReadMs: lastReadMs ?? this.lastReadMs,
  );
  ChannelReadMark copyWithCompanion(ChannelReadMarksCompanion data) {
    return ChannelReadMark(
      nodeScope: data.nodeScope.present ? data.nodeScope.value : this.nodeScope,
      idKey: data.idKey.present ? data.idKey.value : this.idKey,
      lastReadMs: data.lastReadMs.present
          ? data.lastReadMs.value
          : this.lastReadMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelReadMark(')
          ..write('nodeScope: $nodeScope, ')
          ..write('idKey: $idKey, ')
          ..write('lastReadMs: $lastReadMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(nodeScope, idKey, lastReadMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelReadMark &&
          other.nodeScope == this.nodeScope &&
          other.idKey == this.idKey &&
          other.lastReadMs == this.lastReadMs);
}

class ChannelReadMarksCompanion extends UpdateCompanion<ChannelReadMark> {
  final Value<String> nodeScope;
  final Value<String> idKey;
  final Value<int> lastReadMs;
  final Value<int> rowid;
  const ChannelReadMarksCompanion({
    this.nodeScope = const Value.absent(),
    this.idKey = const Value.absent(),
    this.lastReadMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelReadMarksCompanion.insert({
    required String nodeScope,
    required String idKey,
    this.lastReadMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : nodeScope = Value(nodeScope),
       idKey = Value(idKey);
  static Insertable<ChannelReadMark> custom({
    Expression<String>? nodeScope,
    Expression<String>? idKey,
    Expression<int>? lastReadMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeScope != null) 'node_scope': nodeScope,
      if (idKey != null) 'id_key': idKey,
      if (lastReadMs != null) 'last_read_ms': lastReadMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelReadMarksCompanion copyWith({
    Value<String>? nodeScope,
    Value<String>? idKey,
    Value<int>? lastReadMs,
    Value<int>? rowid,
  }) {
    return ChannelReadMarksCompanion(
      nodeScope: nodeScope ?? this.nodeScope,
      idKey: idKey ?? this.idKey,
      lastReadMs: lastReadMs ?? this.lastReadMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeScope.present) {
      map['node_scope'] = Variable<String>(nodeScope.value);
    }
    if (idKey.present) {
      map['id_key'] = Variable<String>(idKey.value);
    }
    if (lastReadMs.present) {
      map['last_read_ms'] = Variable<int>(lastReadMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelReadMarksCompanion(')
          ..write('nodeScope: $nodeScope, ')
          ..write('idKey: $idKey, ')
          ..write('lastReadMs: $lastReadMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactReadMarksTable extends ContactReadMarks
    with TableInfo<$ContactReadMarksTable, ContactReadMark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactReadMarksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _contactKeyMeta = const VerificationMeta(
    'contactKey',
  );
  @override
  late final GeneratedColumn<String> contactKey = GeneratedColumn<String>(
    'contact_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReadMsMeta = const VerificationMeta(
    'lastReadMs',
  );
  @override
  late final GeneratedColumn<int> lastReadMs = GeneratedColumn<int>(
    'last_read_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [nodeScope, contactKey, lastReadMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_read_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactReadMark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_scope')) {
      context.handle(
        _nodeScopeMeta,
        nodeScope.isAcceptableOrUnknown(data['node_scope']!, _nodeScopeMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeScopeMeta);
    }
    if (data.containsKey('contact_key')) {
      context.handle(
        _contactKeyMeta,
        contactKey.isAcceptableOrUnknown(data['contact_key']!, _contactKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_contactKeyMeta);
    }
    if (data.containsKey('last_read_ms')) {
      context.handle(
        _lastReadMsMeta,
        lastReadMs.isAcceptableOrUnknown(
          data['last_read_ms']!,
          _lastReadMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nodeScope, contactKey};
  @override
  ContactReadMark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactReadMark(
      nodeScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_scope'],
      )!,
      contactKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_key'],
      )!,
      lastReadMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_ms'],
      )!,
    );
  }

  @override
  $ContactReadMarksTable createAlias(String alias) {
    return $ContactReadMarksTable(attachedDatabase, alias);
  }
}

class ContactReadMark extends DataClass implements Insertable<ContactReadMark> {
  final String nodeScope;
  final String contactKey;
  final int lastReadMs;
  const ContactReadMark({
    required this.nodeScope,
    required this.contactKey,
    required this.lastReadMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_scope'] = Variable<String>(nodeScope);
    map['contact_key'] = Variable<String>(contactKey);
    map['last_read_ms'] = Variable<int>(lastReadMs);
    return map;
  }

  ContactReadMarksCompanion toCompanion(bool nullToAbsent) {
    return ContactReadMarksCompanion(
      nodeScope: Value(nodeScope),
      contactKey: Value(contactKey),
      lastReadMs: Value(lastReadMs),
    );
  }

  factory ContactReadMark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactReadMark(
      nodeScope: serializer.fromJson<String>(json['nodeScope']),
      contactKey: serializer.fromJson<String>(json['contactKey']),
      lastReadMs: serializer.fromJson<int>(json['lastReadMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeScope': serializer.toJson<String>(nodeScope),
      'contactKey': serializer.toJson<String>(contactKey),
      'lastReadMs': serializer.toJson<int>(lastReadMs),
    };
  }

  ContactReadMark copyWith({
    String? nodeScope,
    String? contactKey,
    int? lastReadMs,
  }) => ContactReadMark(
    nodeScope: nodeScope ?? this.nodeScope,
    contactKey: contactKey ?? this.contactKey,
    lastReadMs: lastReadMs ?? this.lastReadMs,
  );
  ContactReadMark copyWithCompanion(ContactReadMarksCompanion data) {
    return ContactReadMark(
      nodeScope: data.nodeScope.present ? data.nodeScope.value : this.nodeScope,
      contactKey: data.contactKey.present
          ? data.contactKey.value
          : this.contactKey,
      lastReadMs: data.lastReadMs.present
          ? data.lastReadMs.value
          : this.lastReadMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactReadMark(')
          ..write('nodeScope: $nodeScope, ')
          ..write('contactKey: $contactKey, ')
          ..write('lastReadMs: $lastReadMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(nodeScope, contactKey, lastReadMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactReadMark &&
          other.nodeScope == this.nodeScope &&
          other.contactKey == this.contactKey &&
          other.lastReadMs == this.lastReadMs);
}

class ContactReadMarksCompanion extends UpdateCompanion<ContactReadMark> {
  final Value<String> nodeScope;
  final Value<String> contactKey;
  final Value<int> lastReadMs;
  final Value<int> rowid;
  const ContactReadMarksCompanion({
    this.nodeScope = const Value.absent(),
    this.contactKey = const Value.absent(),
    this.lastReadMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactReadMarksCompanion.insert({
    required String nodeScope,
    required String contactKey,
    this.lastReadMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : nodeScope = Value(nodeScope),
       contactKey = Value(contactKey);
  static Insertable<ContactReadMark> custom({
    Expression<String>? nodeScope,
    Expression<String>? contactKey,
    Expression<int>? lastReadMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeScope != null) 'node_scope': nodeScope,
      if (contactKey != null) 'contact_key': contactKey,
      if (lastReadMs != null) 'last_read_ms': lastReadMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactReadMarksCompanion copyWith({
    Value<String>? nodeScope,
    Value<String>? contactKey,
    Value<int>? lastReadMs,
    Value<int>? rowid,
  }) {
    return ContactReadMarksCompanion(
      nodeScope: nodeScope ?? this.nodeScope,
      contactKey: contactKey ?? this.contactKey,
      lastReadMs: lastReadMs ?? this.lastReadMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeScope.present) {
      map['node_scope'] = Variable<String>(nodeScope.value);
    }
    if (contactKey.present) {
      map['contact_key'] = Variable<String>(contactKey.value);
    }
    if (lastReadMs.present) {
      map['last_read_ms'] = Variable<int>(lastReadMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactReadMarksCompanion(')
          ..write('nodeScope: $nodeScope, ')
          ..write('contactKey: $contactKey, ')
          ..write('lastReadMs: $lastReadMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactRowsTable extends ContactRows
    with TableInfo<$ContactRowsTable, ContactRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _publicKeyHexMeta = const VerificationMeta(
    'publicKeyHex',
  );
  @override
  late final GeneratedColumn<String> publicKeyHex = GeneratedColumn<String>(
    'public_key_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  List<GeneratedColumn> get $columns => [nodeScope, publicKeyHex, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_scope')) {
      context.handle(
        _nodeScopeMeta,
        nodeScope.isAcceptableOrUnknown(data['node_scope']!, _nodeScopeMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeScopeMeta);
    }
    if (data.containsKey('public_key_hex')) {
      context.handle(
        _publicKeyHexMeta,
        publicKeyHex.isAcceptableOrUnknown(
          data['public_key_hex']!,
          _publicKeyHexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicKeyHexMeta);
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
  Set<GeneratedColumn> get $primaryKey => {nodeScope, publicKeyHex};
  @override
  ContactRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactRow(
      nodeScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_scope'],
      )!,
      publicKeyHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key_hex'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $ContactRowsTable createAlias(String alias) {
    return $ContactRowsTable(attachedDatabase, alias);
  }
}

class ContactRow extends DataClass implements Insertable<ContactRow> {
  final String nodeScope;
  final String publicKeyHex;
  final String payload;
  const ContactRow({
    required this.nodeScope,
    required this.publicKeyHex,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_scope'] = Variable<String>(nodeScope);
    map['public_key_hex'] = Variable<String>(publicKeyHex);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  ContactRowsCompanion toCompanion(bool nullToAbsent) {
    return ContactRowsCompanion(
      nodeScope: Value(nodeScope),
      publicKeyHex: Value(publicKeyHex),
      payload: Value(payload),
    );
  }

  factory ContactRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactRow(
      nodeScope: serializer.fromJson<String>(json['nodeScope']),
      publicKeyHex: serializer.fromJson<String>(json['publicKeyHex']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeScope': serializer.toJson<String>(nodeScope),
      'publicKeyHex': serializer.toJson<String>(publicKeyHex),
      'payload': serializer.toJson<String>(payload),
    };
  }

  ContactRow copyWith({
    String? nodeScope,
    String? publicKeyHex,
    String? payload,
  }) => ContactRow(
    nodeScope: nodeScope ?? this.nodeScope,
    publicKeyHex: publicKeyHex ?? this.publicKeyHex,
    payload: payload ?? this.payload,
  );
  ContactRow copyWithCompanion(ContactRowsCompanion data) {
    return ContactRow(
      nodeScope: data.nodeScope.present ? data.nodeScope.value : this.nodeScope,
      publicKeyHex: data.publicKeyHex.present
          ? data.publicKeyHex.value
          : this.publicKeyHex,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactRow(')
          ..write('nodeScope: $nodeScope, ')
          ..write('publicKeyHex: $publicKeyHex, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(nodeScope, publicKeyHex, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactRow &&
          other.nodeScope == this.nodeScope &&
          other.publicKeyHex == this.publicKeyHex &&
          other.payload == this.payload);
}

class ContactRowsCompanion extends UpdateCompanion<ContactRow> {
  final Value<String> nodeScope;
  final Value<String> publicKeyHex;
  final Value<String> payload;
  final Value<int> rowid;
  const ContactRowsCompanion({
    this.nodeScope = const Value.absent(),
    this.publicKeyHex = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactRowsCompanion.insert({
    required String nodeScope,
    required String publicKeyHex,
    required String payload,
    this.rowid = const Value.absent(),
  }) : nodeScope = Value(nodeScope),
       publicKeyHex = Value(publicKeyHex),
       payload = Value(payload);
  static Insertable<ContactRow> custom({
    Expression<String>? nodeScope,
    Expression<String>? publicKeyHex,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeScope != null) 'node_scope': nodeScope,
      if (publicKeyHex != null) 'public_key_hex': publicKeyHex,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactRowsCompanion copyWith({
    Value<String>? nodeScope,
    Value<String>? publicKeyHex,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return ContactRowsCompanion(
      nodeScope: nodeScope ?? this.nodeScope,
      publicKeyHex: publicKeyHex ?? this.publicKeyHex,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeScope.present) {
      map['node_scope'] = Variable<String>(nodeScope.value);
    }
    if (publicKeyHex.present) {
      map['public_key_hex'] = Variable<String>(publicKeyHex.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactRowsCompanion(')
          ..write('nodeScope: $nodeScope, ')
          ..write('publicKeyHex: $publicKeyHex, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiscoveredContactRowsTable extends DiscoveredContactRows
    with TableInfo<$DiscoveredContactRowsTable, DiscoveredContactRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiscoveredContactRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _publicKeyHexMeta = const VerificationMeta(
    'publicKeyHex',
  );
  @override
  late final GeneratedColumn<String> publicKeyHex = GeneratedColumn<String>(
    'public_key_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  List<GeneratedColumn> get $columns => [nodeScope, publicKeyHex, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discovered_contact_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiscoveredContactRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_scope')) {
      context.handle(
        _nodeScopeMeta,
        nodeScope.isAcceptableOrUnknown(data['node_scope']!, _nodeScopeMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeScopeMeta);
    }
    if (data.containsKey('public_key_hex')) {
      context.handle(
        _publicKeyHexMeta,
        publicKeyHex.isAcceptableOrUnknown(
          data['public_key_hex']!,
          _publicKeyHexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicKeyHexMeta);
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
  Set<GeneratedColumn> get $primaryKey => {nodeScope, publicKeyHex};
  @override
  DiscoveredContactRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiscoveredContactRow(
      nodeScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_scope'],
      )!,
      publicKeyHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key_hex'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $DiscoveredContactRowsTable createAlias(String alias) {
    return $DiscoveredContactRowsTable(attachedDatabase, alias);
  }
}

class DiscoveredContactRow extends DataClass
    implements Insertable<DiscoveredContactRow> {
  final String nodeScope;
  final String publicKeyHex;
  final String payload;
  const DiscoveredContactRow({
    required this.nodeScope,
    required this.publicKeyHex,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_scope'] = Variable<String>(nodeScope);
    map['public_key_hex'] = Variable<String>(publicKeyHex);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  DiscoveredContactRowsCompanion toCompanion(bool nullToAbsent) {
    return DiscoveredContactRowsCompanion(
      nodeScope: Value(nodeScope),
      publicKeyHex: Value(publicKeyHex),
      payload: Value(payload),
    );
  }

  factory DiscoveredContactRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiscoveredContactRow(
      nodeScope: serializer.fromJson<String>(json['nodeScope']),
      publicKeyHex: serializer.fromJson<String>(json['publicKeyHex']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeScope': serializer.toJson<String>(nodeScope),
      'publicKeyHex': serializer.toJson<String>(publicKeyHex),
      'payload': serializer.toJson<String>(payload),
    };
  }

  DiscoveredContactRow copyWith({
    String? nodeScope,
    String? publicKeyHex,
    String? payload,
  }) => DiscoveredContactRow(
    nodeScope: nodeScope ?? this.nodeScope,
    publicKeyHex: publicKeyHex ?? this.publicKeyHex,
    payload: payload ?? this.payload,
  );
  DiscoveredContactRow copyWithCompanion(DiscoveredContactRowsCompanion data) {
    return DiscoveredContactRow(
      nodeScope: data.nodeScope.present ? data.nodeScope.value : this.nodeScope,
      publicKeyHex: data.publicKeyHex.present
          ? data.publicKeyHex.value
          : this.publicKeyHex,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiscoveredContactRow(')
          ..write('nodeScope: $nodeScope, ')
          ..write('publicKeyHex: $publicKeyHex, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(nodeScope, publicKeyHex, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiscoveredContactRow &&
          other.nodeScope == this.nodeScope &&
          other.publicKeyHex == this.publicKeyHex &&
          other.payload == this.payload);
}

class DiscoveredContactRowsCompanion
    extends UpdateCompanion<DiscoveredContactRow> {
  final Value<String> nodeScope;
  final Value<String> publicKeyHex;
  final Value<String> payload;
  final Value<int> rowid;
  const DiscoveredContactRowsCompanion({
    this.nodeScope = const Value.absent(),
    this.publicKeyHex = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiscoveredContactRowsCompanion.insert({
    required String nodeScope,
    required String publicKeyHex,
    required String payload,
    this.rowid = const Value.absent(),
  }) : nodeScope = Value(nodeScope),
       publicKeyHex = Value(publicKeyHex),
       payload = Value(payload);
  static Insertable<DiscoveredContactRow> custom({
    Expression<String>? nodeScope,
    Expression<String>? publicKeyHex,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeScope != null) 'node_scope': nodeScope,
      if (publicKeyHex != null) 'public_key_hex': publicKeyHex,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiscoveredContactRowsCompanion copyWith({
    Value<String>? nodeScope,
    Value<String>? publicKeyHex,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return DiscoveredContactRowsCompanion(
      nodeScope: nodeScope ?? this.nodeScope,
      publicKeyHex: publicKeyHex ?? this.publicKeyHex,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeScope.present) {
      map['node_scope'] = Variable<String>(nodeScope.value);
    }
    if (publicKeyHex.present) {
      map['public_key_hex'] = Variable<String>(publicKeyHex.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiscoveredContactRowsCompanion(')
          ..write('nodeScope: $nodeScope, ')
          ..write('publicKeyHex: $publicKeyHex, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedChannelRowsTable extends CachedChannelRows
    with TableInfo<$CachedChannelRowsTable, CachedChannelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedChannelRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _slotIndexMeta = const VerificationMeta(
    'slotIndex',
  );
  @override
  late final GeneratedColumn<int> slotIndex = GeneratedColumn<int>(
    'slot_index',
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
  List<GeneratedColumn> get $columns => [nodeScope, slotIndex, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_channel_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedChannelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_scope')) {
      context.handle(
        _nodeScopeMeta,
        nodeScope.isAcceptableOrUnknown(data['node_scope']!, _nodeScopeMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeScopeMeta);
    }
    if (data.containsKey('slot_index')) {
      context.handle(
        _slotIndexMeta,
        slotIndex.isAcceptableOrUnknown(data['slot_index']!, _slotIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_slotIndexMeta);
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
  Set<GeneratedColumn> get $primaryKey => {nodeScope, slotIndex};
  @override
  CachedChannelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedChannelRow(
      nodeScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_scope'],
      )!,
      slotIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot_index'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $CachedChannelRowsTable createAlias(String alias) {
    return $CachedChannelRowsTable(attachedDatabase, alias);
  }
}

class CachedChannelRow extends DataClass
    implements Insertable<CachedChannelRow> {
  final String nodeScope;
  final int slotIndex;
  final String payload;
  const CachedChannelRow({
    required this.nodeScope,
    required this.slotIndex,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_scope'] = Variable<String>(nodeScope);
    map['slot_index'] = Variable<int>(slotIndex);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  CachedChannelRowsCompanion toCompanion(bool nullToAbsent) {
    return CachedChannelRowsCompanion(
      nodeScope: Value(nodeScope),
      slotIndex: Value(slotIndex),
      payload: Value(payload),
    );
  }

  factory CachedChannelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedChannelRow(
      nodeScope: serializer.fromJson<String>(json['nodeScope']),
      slotIndex: serializer.fromJson<int>(json['slotIndex']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeScope': serializer.toJson<String>(nodeScope),
      'slotIndex': serializer.toJson<int>(slotIndex),
      'payload': serializer.toJson<String>(payload),
    };
  }

  CachedChannelRow copyWith({
    String? nodeScope,
    int? slotIndex,
    String? payload,
  }) => CachedChannelRow(
    nodeScope: nodeScope ?? this.nodeScope,
    slotIndex: slotIndex ?? this.slotIndex,
    payload: payload ?? this.payload,
  );
  CachedChannelRow copyWithCompanion(CachedChannelRowsCompanion data) {
    return CachedChannelRow(
      nodeScope: data.nodeScope.present ? data.nodeScope.value : this.nodeScope,
      slotIndex: data.slotIndex.present ? data.slotIndex.value : this.slotIndex,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedChannelRow(')
          ..write('nodeScope: $nodeScope, ')
          ..write('slotIndex: $slotIndex, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(nodeScope, slotIndex, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedChannelRow &&
          other.nodeScope == this.nodeScope &&
          other.slotIndex == this.slotIndex &&
          other.payload == this.payload);
}

class CachedChannelRowsCompanion extends UpdateCompanion<CachedChannelRow> {
  final Value<String> nodeScope;
  final Value<int> slotIndex;
  final Value<String> payload;
  final Value<int> rowid;
  const CachedChannelRowsCompanion({
    this.nodeScope = const Value.absent(),
    this.slotIndex = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedChannelRowsCompanion.insert({
    required String nodeScope,
    required int slotIndex,
    required String payload,
    this.rowid = const Value.absent(),
  }) : nodeScope = Value(nodeScope),
       slotIndex = Value(slotIndex),
       payload = Value(payload);
  static Insertable<CachedChannelRow> custom({
    Expression<String>? nodeScope,
    Expression<int>? slotIndex,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeScope != null) 'node_scope': nodeScope,
      if (slotIndex != null) 'slot_index': slotIndex,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedChannelRowsCompanion copyWith({
    Value<String>? nodeScope,
    Value<int>? slotIndex,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return CachedChannelRowsCompanion(
      nodeScope: nodeScope ?? this.nodeScope,
      slotIndex: slotIndex ?? this.slotIndex,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeScope.present) {
      map['node_scope'] = Variable<String>(nodeScope.value);
    }
    if (slotIndex.present) {
      map['slot_index'] = Variable<int>(slotIndex.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedChannelRowsCompanion(')
          ..write('nodeScope: $nodeScope, ')
          ..write('slotIndex: $slotIndex, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChannelMessageRowsTable channelMessageRows =
      $ChannelMessageRowsTable(this);
  late final $ContactMessageRowsTable contactMessageRows =
      $ContactMessageRowsTable(this);
  late final $ChannelReadMarksTable channelReadMarks = $ChannelReadMarksTable(
    this,
  );
  late final $ContactReadMarksTable contactReadMarks = $ContactReadMarksTable(
    this,
  );
  late final $ContactRowsTable contactRows = $ContactRowsTable(this);
  late final $DiscoveredContactRowsTable discoveredContactRows =
      $DiscoveredContactRowsTable(this);
  late final $CachedChannelRowsTable cachedChannelRows =
      $CachedChannelRowsTable(this);
  late final Index idxChannelPacketHash = Index(
    'idx_channel_packet_hash',
    'CREATE INDEX idx_channel_packet_hash ON channel_message_rows (node_scope, channel_id_key, packet_hash)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    channelMessageRows,
    contactMessageRows,
    channelReadMarks,
    contactReadMarks,
    contactRows,
    discoveredContactRows,
    cachedChannelRows,
    idxChannelPacketHash,
  ];
}

typedef $$ChannelMessageRowsTableCreateCompanionBuilder =
    ChannelMessageRowsCompanion Function({
      Value<int> id,
      required String nodeScope,
      required String channelIdKey,
      required String messageId,
      required int timestampMs,
      Value<String?> packetHash,
      Value<bool> isOutgoing,
      Value<bool> unreadEligible,
      required String payload,
    });
typedef $$ChannelMessageRowsTableUpdateCompanionBuilder =
    ChannelMessageRowsCompanion Function({
      Value<int> id,
      Value<String> nodeScope,
      Value<String> channelIdKey,
      Value<String> messageId,
      Value<int> timestampMs,
      Value<String?> packetHash,
      Value<bool> isOutgoing,
      Value<bool> unreadEligible,
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

  ColumnFilters<String> get packetHash => $composableBuilder(
    column: $table.packetHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unreadEligible => $composableBuilder(
    column: $table.unreadEligible,
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

  ColumnOrderings<String> get packetHash => $composableBuilder(
    column: $table.packetHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unreadEligible => $composableBuilder(
    column: $table.unreadEligible,
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

  GeneratedColumn<String> get packetHash => $composableBuilder(
    column: $table.packetHash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get unreadEligible => $composableBuilder(
    column: $table.unreadEligible,
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
                Value<String?> packetHash = const Value.absent(),
                Value<bool> isOutgoing = const Value.absent(),
                Value<bool> unreadEligible = const Value.absent(),
                Value<String> payload = const Value.absent(),
              }) => ChannelMessageRowsCompanion(
                id: id,
                nodeScope: nodeScope,
                channelIdKey: channelIdKey,
                messageId: messageId,
                timestampMs: timestampMs,
                packetHash: packetHash,
                isOutgoing: isOutgoing,
                unreadEligible: unreadEligible,
                payload: payload,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nodeScope,
                required String channelIdKey,
                required String messageId,
                required int timestampMs,
                Value<String?> packetHash = const Value.absent(),
                Value<bool> isOutgoing = const Value.absent(),
                Value<bool> unreadEligible = const Value.absent(),
                required String payload,
              }) => ChannelMessageRowsCompanion.insert(
                id: id,
                nodeScope: nodeScope,
                channelIdKey: channelIdKey,
                messageId: messageId,
                timestampMs: timestampMs,
                packetHash: packetHash,
                isOutgoing: isOutgoing,
                unreadEligible: unreadEligible,
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
typedef $$ContactMessageRowsTableCreateCompanionBuilder =
    ContactMessageRowsCompanion Function({
      Value<int> id,
      required String nodeScope,
      required String contactKey,
      required String messageId,
      required int timestampMs,
      Value<bool> isOutgoing,
      Value<bool> unreadEligible,
      required String payload,
    });
typedef $$ContactMessageRowsTableUpdateCompanionBuilder =
    ContactMessageRowsCompanion Function({
      Value<int> id,
      Value<String> nodeScope,
      Value<String> contactKey,
      Value<String> messageId,
      Value<int> timestampMs,
      Value<bool> isOutgoing,
      Value<bool> unreadEligible,
      Value<String> payload,
    });

class $$ContactMessageRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactMessageRowsTable> {
  $$ContactMessageRowsTableFilterComposer({
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

  ColumnFilters<String> get contactKey => $composableBuilder(
    column: $table.contactKey,
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

  ColumnFilters<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unreadEligible => $composableBuilder(
    column: $table.unreadEligible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactMessageRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactMessageRowsTable> {
  $$ContactMessageRowsTableOrderingComposer({
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

  ColumnOrderings<String> get contactKey => $composableBuilder(
    column: $table.contactKey,
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

  ColumnOrderings<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unreadEligible => $composableBuilder(
    column: $table.unreadEligible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactMessageRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactMessageRowsTable> {
  $$ContactMessageRowsTableAnnotationComposer({
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

  GeneratedColumn<String> get contactKey => $composableBuilder(
    column: $table.contactKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get unreadEligible => $composableBuilder(
    column: $table.unreadEligible,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$ContactMessageRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactMessageRowsTable,
          ContactMessageRow,
          $$ContactMessageRowsTableFilterComposer,
          $$ContactMessageRowsTableOrderingComposer,
          $$ContactMessageRowsTableAnnotationComposer,
          $$ContactMessageRowsTableCreateCompanionBuilder,
          $$ContactMessageRowsTableUpdateCompanionBuilder,
          (
            ContactMessageRow,
            BaseReferences<
              _$AppDatabase,
              $ContactMessageRowsTable,
              ContactMessageRow
            >,
          ),
          ContactMessageRow,
          PrefetchHooks Function()
        > {
  $$ContactMessageRowsTableTableManager(
    _$AppDatabase db,
    $ContactMessageRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactMessageRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactMessageRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactMessageRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nodeScope = const Value.absent(),
                Value<String> contactKey = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<int> timestampMs = const Value.absent(),
                Value<bool> isOutgoing = const Value.absent(),
                Value<bool> unreadEligible = const Value.absent(),
                Value<String> payload = const Value.absent(),
              }) => ContactMessageRowsCompanion(
                id: id,
                nodeScope: nodeScope,
                contactKey: contactKey,
                messageId: messageId,
                timestampMs: timestampMs,
                isOutgoing: isOutgoing,
                unreadEligible: unreadEligible,
                payload: payload,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nodeScope,
                required String contactKey,
                required String messageId,
                required int timestampMs,
                Value<bool> isOutgoing = const Value.absent(),
                Value<bool> unreadEligible = const Value.absent(),
                required String payload,
              }) => ContactMessageRowsCompanion.insert(
                id: id,
                nodeScope: nodeScope,
                contactKey: contactKey,
                messageId: messageId,
                timestampMs: timestampMs,
                isOutgoing: isOutgoing,
                unreadEligible: unreadEligible,
                payload: payload,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContactMessageRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactMessageRowsTable,
      ContactMessageRow,
      $$ContactMessageRowsTableFilterComposer,
      $$ContactMessageRowsTableOrderingComposer,
      $$ContactMessageRowsTableAnnotationComposer,
      $$ContactMessageRowsTableCreateCompanionBuilder,
      $$ContactMessageRowsTableUpdateCompanionBuilder,
      (
        ContactMessageRow,
        BaseReferences<
          _$AppDatabase,
          $ContactMessageRowsTable,
          ContactMessageRow
        >,
      ),
      ContactMessageRow,
      PrefetchHooks Function()
    >;
typedef $$ChannelReadMarksTableCreateCompanionBuilder =
    ChannelReadMarksCompanion Function({
      required String nodeScope,
      required String idKey,
      Value<int> lastReadMs,
      Value<int> rowid,
    });
typedef $$ChannelReadMarksTableUpdateCompanionBuilder =
    ChannelReadMarksCompanion Function({
      Value<String> nodeScope,
      Value<String> idKey,
      Value<int> lastReadMs,
      Value<int> rowid,
    });

class $$ChannelReadMarksTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelReadMarksTable> {
  $$ChannelReadMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idKey => $composableBuilder(
    column: $table.idKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReadMs => $composableBuilder(
    column: $table.lastReadMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChannelReadMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelReadMarksTable> {
  $$ChannelReadMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idKey => $composableBuilder(
    column: $table.idKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReadMs => $composableBuilder(
    column: $table.lastReadMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelReadMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelReadMarksTable> {
  $$ChannelReadMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nodeScope =>
      $composableBuilder(column: $table.nodeScope, builder: (column) => column);

  GeneratedColumn<String> get idKey =>
      $composableBuilder(column: $table.idKey, builder: (column) => column);

  GeneratedColumn<int> get lastReadMs => $composableBuilder(
    column: $table.lastReadMs,
    builder: (column) => column,
  );
}

class $$ChannelReadMarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelReadMarksTable,
          ChannelReadMark,
          $$ChannelReadMarksTableFilterComposer,
          $$ChannelReadMarksTableOrderingComposer,
          $$ChannelReadMarksTableAnnotationComposer,
          $$ChannelReadMarksTableCreateCompanionBuilder,
          $$ChannelReadMarksTableUpdateCompanionBuilder,
          (
            ChannelReadMark,
            BaseReferences<
              _$AppDatabase,
              $ChannelReadMarksTable,
              ChannelReadMark
            >,
          ),
          ChannelReadMark,
          PrefetchHooks Function()
        > {
  $$ChannelReadMarksTableTableManager(
    _$AppDatabase db,
    $ChannelReadMarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelReadMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelReadMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelReadMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> nodeScope = const Value.absent(),
                Value<String> idKey = const Value.absent(),
                Value<int> lastReadMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelReadMarksCompanion(
                nodeScope: nodeScope,
                idKey: idKey,
                lastReadMs: lastReadMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeScope,
                required String idKey,
                Value<int> lastReadMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelReadMarksCompanion.insert(
                nodeScope: nodeScope,
                idKey: idKey,
                lastReadMs: lastReadMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChannelReadMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelReadMarksTable,
      ChannelReadMark,
      $$ChannelReadMarksTableFilterComposer,
      $$ChannelReadMarksTableOrderingComposer,
      $$ChannelReadMarksTableAnnotationComposer,
      $$ChannelReadMarksTableCreateCompanionBuilder,
      $$ChannelReadMarksTableUpdateCompanionBuilder,
      (
        ChannelReadMark,
        BaseReferences<_$AppDatabase, $ChannelReadMarksTable, ChannelReadMark>,
      ),
      ChannelReadMark,
      PrefetchHooks Function()
    >;
typedef $$ContactReadMarksTableCreateCompanionBuilder =
    ContactReadMarksCompanion Function({
      required String nodeScope,
      required String contactKey,
      Value<int> lastReadMs,
      Value<int> rowid,
    });
typedef $$ContactReadMarksTableUpdateCompanionBuilder =
    ContactReadMarksCompanion Function({
      Value<String> nodeScope,
      Value<String> contactKey,
      Value<int> lastReadMs,
      Value<int> rowid,
    });

class $$ContactReadMarksTableFilterComposer
    extends Composer<_$AppDatabase, $ContactReadMarksTable> {
  $$ContactReadMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactKey => $composableBuilder(
    column: $table.contactKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReadMs => $composableBuilder(
    column: $table.lastReadMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactReadMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactReadMarksTable> {
  $$ContactReadMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactKey => $composableBuilder(
    column: $table.contactKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReadMs => $composableBuilder(
    column: $table.lastReadMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactReadMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactReadMarksTable> {
  $$ContactReadMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nodeScope =>
      $composableBuilder(column: $table.nodeScope, builder: (column) => column);

  GeneratedColumn<String> get contactKey => $composableBuilder(
    column: $table.contactKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReadMs => $composableBuilder(
    column: $table.lastReadMs,
    builder: (column) => column,
  );
}

class $$ContactReadMarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactReadMarksTable,
          ContactReadMark,
          $$ContactReadMarksTableFilterComposer,
          $$ContactReadMarksTableOrderingComposer,
          $$ContactReadMarksTableAnnotationComposer,
          $$ContactReadMarksTableCreateCompanionBuilder,
          $$ContactReadMarksTableUpdateCompanionBuilder,
          (
            ContactReadMark,
            BaseReferences<
              _$AppDatabase,
              $ContactReadMarksTable,
              ContactReadMark
            >,
          ),
          ContactReadMark,
          PrefetchHooks Function()
        > {
  $$ContactReadMarksTableTableManager(
    _$AppDatabase db,
    $ContactReadMarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactReadMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactReadMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactReadMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> nodeScope = const Value.absent(),
                Value<String> contactKey = const Value.absent(),
                Value<int> lastReadMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactReadMarksCompanion(
                nodeScope: nodeScope,
                contactKey: contactKey,
                lastReadMs: lastReadMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeScope,
                required String contactKey,
                Value<int> lastReadMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactReadMarksCompanion.insert(
                nodeScope: nodeScope,
                contactKey: contactKey,
                lastReadMs: lastReadMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContactReadMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactReadMarksTable,
      ContactReadMark,
      $$ContactReadMarksTableFilterComposer,
      $$ContactReadMarksTableOrderingComposer,
      $$ContactReadMarksTableAnnotationComposer,
      $$ContactReadMarksTableCreateCompanionBuilder,
      $$ContactReadMarksTableUpdateCompanionBuilder,
      (
        ContactReadMark,
        BaseReferences<_$AppDatabase, $ContactReadMarksTable, ContactReadMark>,
      ),
      ContactReadMark,
      PrefetchHooks Function()
    >;
typedef $$ContactRowsTableCreateCompanionBuilder =
    ContactRowsCompanion Function({
      required String nodeScope,
      required String publicKeyHex,
      required String payload,
      Value<int> rowid,
    });
typedef $$ContactRowsTableUpdateCompanionBuilder =
    ContactRowsCompanion Function({
      Value<String> nodeScope,
      Value<String> publicKeyHex,
      Value<String> payload,
      Value<int> rowid,
    });

class $$ContactRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactRowsTable> {
  $$ContactRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKeyHex => $composableBuilder(
    column: $table.publicKeyHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactRowsTable> {
  $$ContactRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKeyHex => $composableBuilder(
    column: $table.publicKeyHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactRowsTable> {
  $$ContactRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nodeScope =>
      $composableBuilder(column: $table.nodeScope, builder: (column) => column);

  GeneratedColumn<String> get publicKeyHex => $composableBuilder(
    column: $table.publicKeyHex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$ContactRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactRowsTable,
          ContactRow,
          $$ContactRowsTableFilterComposer,
          $$ContactRowsTableOrderingComposer,
          $$ContactRowsTableAnnotationComposer,
          $$ContactRowsTableCreateCompanionBuilder,
          $$ContactRowsTableUpdateCompanionBuilder,
          (
            ContactRow,
            BaseReferences<_$AppDatabase, $ContactRowsTable, ContactRow>,
          ),
          ContactRow,
          PrefetchHooks Function()
        > {
  $$ContactRowsTableTableManager(_$AppDatabase db, $ContactRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> nodeScope = const Value.absent(),
                Value<String> publicKeyHex = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactRowsCompanion(
                nodeScope: nodeScope,
                publicKeyHex: publicKeyHex,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeScope,
                required String publicKeyHex,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => ContactRowsCompanion.insert(
                nodeScope: nodeScope,
                publicKeyHex: publicKeyHex,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContactRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactRowsTable,
      ContactRow,
      $$ContactRowsTableFilterComposer,
      $$ContactRowsTableOrderingComposer,
      $$ContactRowsTableAnnotationComposer,
      $$ContactRowsTableCreateCompanionBuilder,
      $$ContactRowsTableUpdateCompanionBuilder,
      (
        ContactRow,
        BaseReferences<_$AppDatabase, $ContactRowsTable, ContactRow>,
      ),
      ContactRow,
      PrefetchHooks Function()
    >;
typedef $$DiscoveredContactRowsTableCreateCompanionBuilder =
    DiscoveredContactRowsCompanion Function({
      required String nodeScope,
      required String publicKeyHex,
      required String payload,
      Value<int> rowid,
    });
typedef $$DiscoveredContactRowsTableUpdateCompanionBuilder =
    DiscoveredContactRowsCompanion Function({
      Value<String> nodeScope,
      Value<String> publicKeyHex,
      Value<String> payload,
      Value<int> rowid,
    });

class $$DiscoveredContactRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DiscoveredContactRowsTable> {
  $$DiscoveredContactRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKeyHex => $composableBuilder(
    column: $table.publicKeyHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DiscoveredContactRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiscoveredContactRowsTable> {
  $$DiscoveredContactRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKeyHex => $composableBuilder(
    column: $table.publicKeyHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiscoveredContactRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiscoveredContactRowsTable> {
  $$DiscoveredContactRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nodeScope =>
      $composableBuilder(column: $table.nodeScope, builder: (column) => column);

  GeneratedColumn<String> get publicKeyHex => $composableBuilder(
    column: $table.publicKeyHex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$DiscoveredContactRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiscoveredContactRowsTable,
          DiscoveredContactRow,
          $$DiscoveredContactRowsTableFilterComposer,
          $$DiscoveredContactRowsTableOrderingComposer,
          $$DiscoveredContactRowsTableAnnotationComposer,
          $$DiscoveredContactRowsTableCreateCompanionBuilder,
          $$DiscoveredContactRowsTableUpdateCompanionBuilder,
          (
            DiscoveredContactRow,
            BaseReferences<
              _$AppDatabase,
              $DiscoveredContactRowsTable,
              DiscoveredContactRow
            >,
          ),
          DiscoveredContactRow,
          PrefetchHooks Function()
        > {
  $$DiscoveredContactRowsTableTableManager(
    _$AppDatabase db,
    $DiscoveredContactRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiscoveredContactRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DiscoveredContactRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DiscoveredContactRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> nodeScope = const Value.absent(),
                Value<String> publicKeyHex = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiscoveredContactRowsCompanion(
                nodeScope: nodeScope,
                publicKeyHex: publicKeyHex,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeScope,
                required String publicKeyHex,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => DiscoveredContactRowsCompanion.insert(
                nodeScope: nodeScope,
                publicKeyHex: publicKeyHex,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiscoveredContactRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiscoveredContactRowsTable,
      DiscoveredContactRow,
      $$DiscoveredContactRowsTableFilterComposer,
      $$DiscoveredContactRowsTableOrderingComposer,
      $$DiscoveredContactRowsTableAnnotationComposer,
      $$DiscoveredContactRowsTableCreateCompanionBuilder,
      $$DiscoveredContactRowsTableUpdateCompanionBuilder,
      (
        DiscoveredContactRow,
        BaseReferences<
          _$AppDatabase,
          $DiscoveredContactRowsTable,
          DiscoveredContactRow
        >,
      ),
      DiscoveredContactRow,
      PrefetchHooks Function()
    >;
typedef $$CachedChannelRowsTableCreateCompanionBuilder =
    CachedChannelRowsCompanion Function({
      required String nodeScope,
      required int slotIndex,
      required String payload,
      Value<int> rowid,
    });
typedef $$CachedChannelRowsTableUpdateCompanionBuilder =
    CachedChannelRowsCompanion Function({
      Value<String> nodeScope,
      Value<int> slotIndex,
      Value<String> payload,
      Value<int> rowid,
    });

class $$CachedChannelRowsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedChannelRowsTable> {
  $$CachedChannelRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slotIndex => $composableBuilder(
    column: $table.slotIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedChannelRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedChannelRowsTable> {
  $$CachedChannelRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nodeScope => $composableBuilder(
    column: $table.nodeScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slotIndex => $composableBuilder(
    column: $table.slotIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedChannelRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedChannelRowsTable> {
  $$CachedChannelRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nodeScope =>
      $composableBuilder(column: $table.nodeScope, builder: (column) => column);

  GeneratedColumn<int> get slotIndex =>
      $composableBuilder(column: $table.slotIndex, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$CachedChannelRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedChannelRowsTable,
          CachedChannelRow,
          $$CachedChannelRowsTableFilterComposer,
          $$CachedChannelRowsTableOrderingComposer,
          $$CachedChannelRowsTableAnnotationComposer,
          $$CachedChannelRowsTableCreateCompanionBuilder,
          $$CachedChannelRowsTableUpdateCompanionBuilder,
          (
            CachedChannelRow,
            BaseReferences<
              _$AppDatabase,
              $CachedChannelRowsTable,
              CachedChannelRow
            >,
          ),
          CachedChannelRow,
          PrefetchHooks Function()
        > {
  $$CachedChannelRowsTableTableManager(
    _$AppDatabase db,
    $CachedChannelRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedChannelRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedChannelRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedChannelRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> nodeScope = const Value.absent(),
                Value<int> slotIndex = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedChannelRowsCompanion(
                nodeScope: nodeScope,
                slotIndex: slotIndex,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeScope,
                required int slotIndex,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => CachedChannelRowsCompanion.insert(
                nodeScope: nodeScope,
                slotIndex: slotIndex,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedChannelRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedChannelRowsTable,
      CachedChannelRow,
      $$CachedChannelRowsTableFilterComposer,
      $$CachedChannelRowsTableOrderingComposer,
      $$CachedChannelRowsTableAnnotationComposer,
      $$CachedChannelRowsTableCreateCompanionBuilder,
      $$CachedChannelRowsTableUpdateCompanionBuilder,
      (
        CachedChannelRow,
        BaseReferences<
          _$AppDatabase,
          $CachedChannelRowsTable,
          CachedChannelRow
        >,
      ),
      CachedChannelRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChannelMessageRowsTableTableManager get channelMessageRows =>
      $$ChannelMessageRowsTableTableManager(_db, _db.channelMessageRows);
  $$ContactMessageRowsTableTableManager get contactMessageRows =>
      $$ContactMessageRowsTableTableManager(_db, _db.contactMessageRows);
  $$ChannelReadMarksTableTableManager get channelReadMarks =>
      $$ChannelReadMarksTableTableManager(_db, _db.channelReadMarks);
  $$ContactReadMarksTableTableManager get contactReadMarks =>
      $$ContactReadMarksTableTableManager(_db, _db.contactReadMarks);
  $$ContactRowsTableTableManager get contactRows =>
      $$ContactRowsTableTableManager(_db, _db.contactRows);
  $$DiscoveredContactRowsTableTableManager get discoveredContactRows =>
      $$DiscoveredContactRowsTableTableManager(_db, _db.discoveredContactRows);
  $$CachedChannelRowsTableTableManager get cachedChannelRows =>
      $$CachedChannelRowsTableTableManager(_db, _db.cachedChannelRows);
}
