// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GraphNodesTable extends GraphNodes
    with TableInfo<$GraphNodesTable, GraphNode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraphNodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hashBytesMeta =
      const VerificationMeta('hashBytes');
  @override
  late final GeneratedColumn<String> hashBytes = GeneratedColumn<String>(
      'hash_bytes', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lastHeardMeta =
      const VerificationMeta('lastHeard');
  @override
  late final GeneratedColumn<int> lastHeard = GeneratedColumn<int>(
      'last_heard', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
      'region', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
      'pubkey', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [hashBytes, name, role, lat, lon, lastHeard, source, region, pubkey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'graph_nodes';
  @override
  VerificationContext validateIntegrity(Insertable<GraphNode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hash_bytes')) {
      context.handle(_hashBytesMeta,
          hashBytes.isAcceptableOrUnknown(data['hash_bytes']!, _hashBytesMeta));
    } else if (isInserting) {
      context.missing(_hashBytesMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    }
    if (data.containsKey('last_heard')) {
      context.handle(_lastHeardMeta,
          lastHeard.isAcceptableOrUnknown(data['last_heard']!, _lastHeardMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('region')) {
      context.handle(_regionMeta,
          region.isAcceptableOrUnknown(data['region']!, _regionMeta));
    }
    if (data.containsKey('pubkey')) {
      context.handle(_pubkeyMeta,
          pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hashBytes};
  @override
  GraphNode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraphNode(
      hashBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hash_bytes'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role']),
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat']),
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon']),
      lastHeard: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_heard']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      region: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}region']),
      pubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pubkey']),
    );
  }

  @override
  $GraphNodesTable createAlias(String alias) {
    return $GraphNodesTable(attachedDatabase, alias);
  }
}

class GraphNode extends DataClass implements Insertable<GraphNode> {
  /// 4 hex chars, uppercase (2-byte hash).
  final String hashBytes;
  final String? name;
  final String? role;
  final double? lat;
  final double? lon;

  /// Arrival-time millis (never wire timestamps).
  final int? lastHeard;

  /// imported | observed | advert
  final String source;
  final String? region;

  /// Full 64-hex pubkey when known (enables re-collapse at other widths).
  final String? pubkey;
  const GraphNode(
      {required this.hashBytes,
      this.name,
      this.role,
      this.lat,
      this.lon,
      this.lastHeard,
      required this.source,
      this.region,
      this.pubkey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hash_bytes'] = Variable<String>(hashBytes);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lon != null) {
      map['lon'] = Variable<double>(lon);
    }
    if (!nullToAbsent || lastHeard != null) {
      map['last_heard'] = Variable<int>(lastHeard);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    if (!nullToAbsent || pubkey != null) {
      map['pubkey'] = Variable<String>(pubkey);
    }
    return map;
  }

  GraphNodesCompanion toCompanion(bool nullToAbsent) {
    return GraphNodesCompanion(
      hashBytes: Value(hashBytes),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lon: lon == null && nullToAbsent ? const Value.absent() : Value(lon),
      lastHeard: lastHeard == null && nullToAbsent
          ? const Value.absent()
          : Value(lastHeard),
      source: Value(source),
      region:
          region == null && nullToAbsent ? const Value.absent() : Value(region),
      pubkey:
          pubkey == null && nullToAbsent ? const Value.absent() : Value(pubkey),
    );
  }

  factory GraphNode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraphNode(
      hashBytes: serializer.fromJson<String>(json['hashBytes']),
      name: serializer.fromJson<String?>(json['name']),
      role: serializer.fromJson<String?>(json['role']),
      lat: serializer.fromJson<double?>(json['lat']),
      lon: serializer.fromJson<double?>(json['lon']),
      lastHeard: serializer.fromJson<int?>(json['lastHeard']),
      source: serializer.fromJson<String>(json['source']),
      region: serializer.fromJson<String?>(json['region']),
      pubkey: serializer.fromJson<String?>(json['pubkey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hashBytes': serializer.toJson<String>(hashBytes),
      'name': serializer.toJson<String?>(name),
      'role': serializer.toJson<String?>(role),
      'lat': serializer.toJson<double?>(lat),
      'lon': serializer.toJson<double?>(lon),
      'lastHeard': serializer.toJson<int?>(lastHeard),
      'source': serializer.toJson<String>(source),
      'region': serializer.toJson<String?>(region),
      'pubkey': serializer.toJson<String?>(pubkey),
    };
  }

  GraphNode copyWith(
          {String? hashBytes,
          Value<String?> name = const Value.absent(),
          Value<String?> role = const Value.absent(),
          Value<double?> lat = const Value.absent(),
          Value<double?> lon = const Value.absent(),
          Value<int?> lastHeard = const Value.absent(),
          String? source,
          Value<String?> region = const Value.absent(),
          Value<String?> pubkey = const Value.absent()}) =>
      GraphNode(
        hashBytes: hashBytes ?? this.hashBytes,
        name: name.present ? name.value : this.name,
        role: role.present ? role.value : this.role,
        lat: lat.present ? lat.value : this.lat,
        lon: lon.present ? lon.value : this.lon,
        lastHeard: lastHeard.present ? lastHeard.value : this.lastHeard,
        source: source ?? this.source,
        region: region.present ? region.value : this.region,
        pubkey: pubkey.present ? pubkey.value : this.pubkey,
      );
  GraphNode copyWithCompanion(GraphNodesCompanion data) {
    return GraphNode(
      hashBytes: data.hashBytes.present ? data.hashBytes.value : this.hashBytes,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      lastHeard: data.lastHeard.present ? data.lastHeard.value : this.lastHeard,
      source: data.source.present ? data.source.value : this.source,
      region: data.region.present ? data.region.value : this.region,
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraphNode(')
          ..write('hashBytes: $hashBytes, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('lastHeard: $lastHeard, ')
          ..write('source: $source, ')
          ..write('region: $region, ')
          ..write('pubkey: $pubkey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      hashBytes, name, role, lat, lon, lastHeard, source, region, pubkey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraphNode &&
          other.hashBytes == this.hashBytes &&
          other.name == this.name &&
          other.role == this.role &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.lastHeard == this.lastHeard &&
          other.source == this.source &&
          other.region == this.region &&
          other.pubkey == this.pubkey);
}

class GraphNodesCompanion extends UpdateCompanion<GraphNode> {
  final Value<String> hashBytes;
  final Value<String?> name;
  final Value<String?> role;
  final Value<double?> lat;
  final Value<double?> lon;
  final Value<int?> lastHeard;
  final Value<String> source;
  final Value<String?> region;
  final Value<String?> pubkey;
  final Value<int> rowid;
  const GraphNodesCompanion({
    this.hashBytes = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.lastHeard = const Value.absent(),
    this.source = const Value.absent(),
    this.region = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GraphNodesCompanion.insert({
    required String hashBytes,
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.lastHeard = const Value.absent(),
    required String source,
    this.region = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : hashBytes = Value(hashBytes),
        source = Value(source);
  static Insertable<GraphNode> custom({
    Expression<String>? hashBytes,
    Expression<String>? name,
    Expression<String>? role,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<int>? lastHeard,
    Expression<String>? source,
    Expression<String>? region,
    Expression<String>? pubkey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hashBytes != null) 'hash_bytes': hashBytes,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (lastHeard != null) 'last_heard': lastHeard,
      if (source != null) 'source': source,
      if (region != null) 'region': region,
      if (pubkey != null) 'pubkey': pubkey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GraphNodesCompanion copyWith(
      {Value<String>? hashBytes,
      Value<String?>? name,
      Value<String?>? role,
      Value<double?>? lat,
      Value<double?>? lon,
      Value<int?>? lastHeard,
      Value<String>? source,
      Value<String?>? region,
      Value<String?>? pubkey,
      Value<int>? rowid}) {
    return GraphNodesCompanion(
      hashBytes: hashBytes ?? this.hashBytes,
      name: name ?? this.name,
      role: role ?? this.role,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      lastHeard: lastHeard ?? this.lastHeard,
      source: source ?? this.source,
      region: region ?? this.region,
      pubkey: pubkey ?? this.pubkey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hashBytes.present) {
      map['hash_bytes'] = Variable<String>(hashBytes.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (lastHeard.present) {
      map['last_heard'] = Variable<int>(lastHeard.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GraphNodesCompanion(')
          ..write('hashBytes: $hashBytes, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('lastHeard: $lastHeard, ')
          ..write('source: $source, ')
          ..write('region: $region, ')
          ..write('pubkey: $pubkey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GraphEdgesTable extends GraphEdges
    with TableInfo<$GraphEdgesTable, GraphEdge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraphEdgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fromHashMeta =
      const VerificationMeta('fromHash');
  @override
  late final GeneratedColumn<String> fromHash = GeneratedColumn<String>(
      'from_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toHashMeta = const VerificationMeta('toHash');
  @override
  late final GeneratedColumn<String> toHash = GeneratedColumn<String>(
      'to_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sMeta = const VerificationMeta('s');
  @override
  late final GeneratedColumn<int> s = GeneratedColumn<int>(
      's', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nMeta = const VerificationMeta('n');
  @override
  late final GeneratedColumn<int> n = GeneratedColumn<int>(
      'n', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _trafficWeightMeta =
      const VerificationMeta('trafficWeight');
  @override
  late final GeneratedColumn<double> trafficWeight = GeneratedColumn<double>(
      'traffic_weight', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastObservedMeta =
      const VerificationMeta('lastObserved');
  @override
  late final GeneratedColumn<int> lastObserved = GeneratedColumn<int>(
      'last_observed', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _obsCountMeta =
      const VerificationMeta('obsCount');
  @override
  late final GeneratedColumn<int> obsCount = GeneratedColumn<int>(
      'obs_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _importedSnrMeta =
      const VerificationMeta('importedSnr');
  @override
  late final GeneratedColumn<double> importedSnr = GeneratedColumn<double>(
      'imported_snr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _importedObservationsMeta =
      const VerificationMeta('importedObservations');
  @override
  late final GeneratedColumn<int> importedObservations = GeneratedColumn<int>(
      'imported_observations', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _importedDeliveredMeta =
      const VerificationMeta('importedDelivered');
  @override
  late final GeneratedColumn<int> importedDelivered = GeneratedColumn<int>(
      'imported_delivered', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _importedAttemptsMeta =
      const VerificationMeta('importedAttempts');
  @override
  late final GeneratedColumn<int> importedAttempts = GeneratedColumn<int>(
      'imported_attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _importedLastObservedMeta =
      const VerificationMeta('importedLastObserved');
  @override
  late final GeneratedColumn<int> importedLastObserved = GeneratedColumn<int>(
      'imported_last_observed', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _measuredSnrMeta =
      const VerificationMeta('measuredSnr');
  @override
  late final GeneratedColumn<double> measuredSnr = GeneratedColumn<double>(
      'measured_snr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        fromHash,
        toHash,
        s,
        n,
        trafficWeight,
        lastObserved,
        obsCount,
        source,
        importedSnr,
        importedObservations,
        importedDelivered,
        importedAttempts,
        importedLastObserved,
        measuredSnr
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'graph_edges';
  @override
  VerificationContext validateIntegrity(Insertable<GraphEdge> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('from_hash')) {
      context.handle(_fromHashMeta,
          fromHash.isAcceptableOrUnknown(data['from_hash']!, _fromHashMeta));
    } else if (isInserting) {
      context.missing(_fromHashMeta);
    }
    if (data.containsKey('to_hash')) {
      context.handle(_toHashMeta,
          toHash.isAcceptableOrUnknown(data['to_hash']!, _toHashMeta));
    } else if (isInserting) {
      context.missing(_toHashMeta);
    }
    if (data.containsKey('s')) {
      context.handle(_sMeta, s.isAcceptableOrUnknown(data['s']!, _sMeta));
    }
    if (data.containsKey('n')) {
      context.handle(_nMeta, n.isAcceptableOrUnknown(data['n']!, _nMeta));
    }
    if (data.containsKey('traffic_weight')) {
      context.handle(
          _trafficWeightMeta,
          trafficWeight.isAcceptableOrUnknown(
              data['traffic_weight']!, _trafficWeightMeta));
    }
    if (data.containsKey('last_observed')) {
      context.handle(
          _lastObservedMeta,
          lastObserved.isAcceptableOrUnknown(
              data['last_observed']!, _lastObservedMeta));
    }
    if (data.containsKey('obs_count')) {
      context.handle(_obsCountMeta,
          obsCount.isAcceptableOrUnknown(data['obs_count']!, _obsCountMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('imported_snr')) {
      context.handle(
          _importedSnrMeta,
          importedSnr.isAcceptableOrUnknown(
              data['imported_snr']!, _importedSnrMeta));
    }
    if (data.containsKey('imported_observations')) {
      context.handle(
          _importedObservationsMeta,
          importedObservations.isAcceptableOrUnknown(
              data['imported_observations']!, _importedObservationsMeta));
    }
    if (data.containsKey('imported_delivered')) {
      context.handle(
          _importedDeliveredMeta,
          importedDelivered.isAcceptableOrUnknown(
              data['imported_delivered']!, _importedDeliveredMeta));
    }
    if (data.containsKey('imported_attempts')) {
      context.handle(
          _importedAttemptsMeta,
          importedAttempts.isAcceptableOrUnknown(
              data['imported_attempts']!, _importedAttemptsMeta));
    }
    if (data.containsKey('imported_last_observed')) {
      context.handle(
          _importedLastObservedMeta,
          importedLastObserved.isAcceptableOrUnknown(
              data['imported_last_observed']!, _importedLastObservedMeta));
    }
    if (data.containsKey('measured_snr')) {
      context.handle(
          _measuredSnrMeta,
          measuredSnr.isAcceptableOrUnknown(
              data['measured_snr']!, _measuredSnrMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fromHash, toHash};
  @override
  GraphEdge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraphEdge(
      fromHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_hash'])!,
      toHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_hash'])!,
      s: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}s'])!,
      n: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}n'])!,
      trafficWeight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}traffic_weight'])!,
      lastObserved: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_observed']),
      obsCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}obs_count'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      importedSnr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}imported_snr']),
      importedObservations: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}imported_observations'])!,
      importedDelivered: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}imported_delivered'])!,
      importedAttempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}imported_attempts'])!,
      importedLastObserved: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}imported_last_observed']),
      measuredSnr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}measured_snr']),
    );
  }

  @override
  $GraphEdgesTable createAlias(String alias) {
    return $GraphEdgesTable(attachedDatabase, alias);
  }
}

class GraphEdge extends DataClass implements Insertable<GraphEdge> {
  final String fromHash;
  final String toHash;

  /// Attempt-counted local evidence (successes / attempts).
  final int s;
  final int n;

  /// Passive-sighting EWMA (candidate ranking / tie-breaks, never p).
  final double trafficWeight;

  /// Arrival-time millis of last observation.
  final int? lastObserved;
  final int obsCount;
  final String source;
  final double? importedSnr;
  final int importedObservations;
  final int importedDelivered;
  final int importedAttempts;
  final int? importedLastObserved;
  final double? measuredSnr;
  const GraphEdge(
      {required this.fromHash,
      required this.toHash,
      required this.s,
      required this.n,
      required this.trafficWeight,
      this.lastObserved,
      required this.obsCount,
      required this.source,
      this.importedSnr,
      required this.importedObservations,
      required this.importedDelivered,
      required this.importedAttempts,
      this.importedLastObserved,
      this.measuredSnr});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_hash'] = Variable<String>(fromHash);
    map['to_hash'] = Variable<String>(toHash);
    map['s'] = Variable<int>(s);
    map['n'] = Variable<int>(n);
    map['traffic_weight'] = Variable<double>(trafficWeight);
    if (!nullToAbsent || lastObserved != null) {
      map['last_observed'] = Variable<int>(lastObserved);
    }
    map['obs_count'] = Variable<int>(obsCount);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || importedSnr != null) {
      map['imported_snr'] = Variable<double>(importedSnr);
    }
    map['imported_observations'] = Variable<int>(importedObservations);
    map['imported_delivered'] = Variable<int>(importedDelivered);
    map['imported_attempts'] = Variable<int>(importedAttempts);
    if (!nullToAbsent || importedLastObserved != null) {
      map['imported_last_observed'] = Variable<int>(importedLastObserved);
    }
    if (!nullToAbsent || measuredSnr != null) {
      map['measured_snr'] = Variable<double>(measuredSnr);
    }
    return map;
  }

  GraphEdgesCompanion toCompanion(bool nullToAbsent) {
    return GraphEdgesCompanion(
      fromHash: Value(fromHash),
      toHash: Value(toHash),
      s: Value(s),
      n: Value(n),
      trafficWeight: Value(trafficWeight),
      lastObserved: lastObserved == null && nullToAbsent
          ? const Value.absent()
          : Value(lastObserved),
      obsCount: Value(obsCount),
      source: Value(source),
      importedSnr: importedSnr == null && nullToAbsent
          ? const Value.absent()
          : Value(importedSnr),
      importedObservations: Value(importedObservations),
      importedDelivered: Value(importedDelivered),
      importedAttempts: Value(importedAttempts),
      importedLastObserved: importedLastObserved == null && nullToAbsent
          ? const Value.absent()
          : Value(importedLastObserved),
      measuredSnr: measuredSnr == null && nullToAbsent
          ? const Value.absent()
          : Value(measuredSnr),
    );
  }

  factory GraphEdge.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraphEdge(
      fromHash: serializer.fromJson<String>(json['fromHash']),
      toHash: serializer.fromJson<String>(json['toHash']),
      s: serializer.fromJson<int>(json['s']),
      n: serializer.fromJson<int>(json['n']),
      trafficWeight: serializer.fromJson<double>(json['trafficWeight']),
      lastObserved: serializer.fromJson<int?>(json['lastObserved']),
      obsCount: serializer.fromJson<int>(json['obsCount']),
      source: serializer.fromJson<String>(json['source']),
      importedSnr: serializer.fromJson<double?>(json['importedSnr']),
      importedObservations:
          serializer.fromJson<int>(json['importedObservations']),
      importedDelivered: serializer.fromJson<int>(json['importedDelivered']),
      importedAttempts: serializer.fromJson<int>(json['importedAttempts']),
      importedLastObserved:
          serializer.fromJson<int?>(json['importedLastObserved']),
      measuredSnr: serializer.fromJson<double?>(json['measuredSnr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromHash': serializer.toJson<String>(fromHash),
      'toHash': serializer.toJson<String>(toHash),
      's': serializer.toJson<int>(s),
      'n': serializer.toJson<int>(n),
      'trafficWeight': serializer.toJson<double>(trafficWeight),
      'lastObserved': serializer.toJson<int?>(lastObserved),
      'obsCount': serializer.toJson<int>(obsCount),
      'source': serializer.toJson<String>(source),
      'importedSnr': serializer.toJson<double?>(importedSnr),
      'importedObservations': serializer.toJson<int>(importedObservations),
      'importedDelivered': serializer.toJson<int>(importedDelivered),
      'importedAttempts': serializer.toJson<int>(importedAttempts),
      'importedLastObserved': serializer.toJson<int?>(importedLastObserved),
      'measuredSnr': serializer.toJson<double?>(measuredSnr),
    };
  }

  GraphEdge copyWith(
          {String? fromHash,
          String? toHash,
          int? s,
          int? n,
          double? trafficWeight,
          Value<int?> lastObserved = const Value.absent(),
          int? obsCount,
          String? source,
          Value<double?> importedSnr = const Value.absent(),
          int? importedObservations,
          int? importedDelivered,
          int? importedAttempts,
          Value<int?> importedLastObserved = const Value.absent(),
          Value<double?> measuredSnr = const Value.absent()}) =>
      GraphEdge(
        fromHash: fromHash ?? this.fromHash,
        toHash: toHash ?? this.toHash,
        s: s ?? this.s,
        n: n ?? this.n,
        trafficWeight: trafficWeight ?? this.trafficWeight,
        lastObserved:
            lastObserved.present ? lastObserved.value : this.lastObserved,
        obsCount: obsCount ?? this.obsCount,
        source: source ?? this.source,
        importedSnr: importedSnr.present ? importedSnr.value : this.importedSnr,
        importedObservations: importedObservations ?? this.importedObservations,
        importedDelivered: importedDelivered ?? this.importedDelivered,
        importedAttempts: importedAttempts ?? this.importedAttempts,
        importedLastObserved: importedLastObserved.present
            ? importedLastObserved.value
            : this.importedLastObserved,
        measuredSnr: measuredSnr.present ? measuredSnr.value : this.measuredSnr,
      );
  GraphEdge copyWithCompanion(GraphEdgesCompanion data) {
    return GraphEdge(
      fromHash: data.fromHash.present ? data.fromHash.value : this.fromHash,
      toHash: data.toHash.present ? data.toHash.value : this.toHash,
      s: data.s.present ? data.s.value : this.s,
      n: data.n.present ? data.n.value : this.n,
      trafficWeight: data.trafficWeight.present
          ? data.trafficWeight.value
          : this.trafficWeight,
      lastObserved: data.lastObserved.present
          ? data.lastObserved.value
          : this.lastObserved,
      obsCount: data.obsCount.present ? data.obsCount.value : this.obsCount,
      source: data.source.present ? data.source.value : this.source,
      importedSnr:
          data.importedSnr.present ? data.importedSnr.value : this.importedSnr,
      importedObservations: data.importedObservations.present
          ? data.importedObservations.value
          : this.importedObservations,
      importedDelivered: data.importedDelivered.present
          ? data.importedDelivered.value
          : this.importedDelivered,
      importedAttempts: data.importedAttempts.present
          ? data.importedAttempts.value
          : this.importedAttempts,
      importedLastObserved: data.importedLastObserved.present
          ? data.importedLastObserved.value
          : this.importedLastObserved,
      measuredSnr:
          data.measuredSnr.present ? data.measuredSnr.value : this.measuredSnr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraphEdge(')
          ..write('fromHash: $fromHash, ')
          ..write('toHash: $toHash, ')
          ..write('s: $s, ')
          ..write('n: $n, ')
          ..write('trafficWeight: $trafficWeight, ')
          ..write('lastObserved: $lastObserved, ')
          ..write('obsCount: $obsCount, ')
          ..write('source: $source, ')
          ..write('importedSnr: $importedSnr, ')
          ..write('importedObservations: $importedObservations, ')
          ..write('importedDelivered: $importedDelivered, ')
          ..write('importedAttempts: $importedAttempts, ')
          ..write('importedLastObserved: $importedLastObserved, ')
          ..write('measuredSnr: $measuredSnr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      fromHash,
      toHash,
      s,
      n,
      trafficWeight,
      lastObserved,
      obsCount,
      source,
      importedSnr,
      importedObservations,
      importedDelivered,
      importedAttempts,
      importedLastObserved,
      measuredSnr);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraphEdge &&
          other.fromHash == this.fromHash &&
          other.toHash == this.toHash &&
          other.s == this.s &&
          other.n == this.n &&
          other.trafficWeight == this.trafficWeight &&
          other.lastObserved == this.lastObserved &&
          other.obsCount == this.obsCount &&
          other.source == this.source &&
          other.importedSnr == this.importedSnr &&
          other.importedObservations == this.importedObservations &&
          other.importedDelivered == this.importedDelivered &&
          other.importedAttempts == this.importedAttempts &&
          other.importedLastObserved == this.importedLastObserved &&
          other.measuredSnr == this.measuredSnr);
}

class GraphEdgesCompanion extends UpdateCompanion<GraphEdge> {
  final Value<String> fromHash;
  final Value<String> toHash;
  final Value<int> s;
  final Value<int> n;
  final Value<double> trafficWeight;
  final Value<int?> lastObserved;
  final Value<int> obsCount;
  final Value<String> source;
  final Value<double?> importedSnr;
  final Value<int> importedObservations;
  final Value<int> importedDelivered;
  final Value<int> importedAttempts;
  final Value<int?> importedLastObserved;
  final Value<double?> measuredSnr;
  final Value<int> rowid;
  const GraphEdgesCompanion({
    this.fromHash = const Value.absent(),
    this.toHash = const Value.absent(),
    this.s = const Value.absent(),
    this.n = const Value.absent(),
    this.trafficWeight = const Value.absent(),
    this.lastObserved = const Value.absent(),
    this.obsCount = const Value.absent(),
    this.source = const Value.absent(),
    this.importedSnr = const Value.absent(),
    this.importedObservations = const Value.absent(),
    this.importedDelivered = const Value.absent(),
    this.importedAttempts = const Value.absent(),
    this.importedLastObserved = const Value.absent(),
    this.measuredSnr = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GraphEdgesCompanion.insert({
    required String fromHash,
    required String toHash,
    this.s = const Value.absent(),
    this.n = const Value.absent(),
    this.trafficWeight = const Value.absent(),
    this.lastObserved = const Value.absent(),
    this.obsCount = const Value.absent(),
    required String source,
    this.importedSnr = const Value.absent(),
    this.importedObservations = const Value.absent(),
    this.importedDelivered = const Value.absent(),
    this.importedAttempts = const Value.absent(),
    this.importedLastObserved = const Value.absent(),
    this.measuredSnr = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : fromHash = Value(fromHash),
        toHash = Value(toHash),
        source = Value(source);
  static Insertable<GraphEdge> custom({
    Expression<String>? fromHash,
    Expression<String>? toHash,
    Expression<int>? s,
    Expression<int>? n,
    Expression<double>? trafficWeight,
    Expression<int>? lastObserved,
    Expression<int>? obsCount,
    Expression<String>? source,
    Expression<double>? importedSnr,
    Expression<int>? importedObservations,
    Expression<int>? importedDelivered,
    Expression<int>? importedAttempts,
    Expression<int>? importedLastObserved,
    Expression<double>? measuredSnr,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromHash != null) 'from_hash': fromHash,
      if (toHash != null) 'to_hash': toHash,
      if (s != null) 's': s,
      if (n != null) 'n': n,
      if (trafficWeight != null) 'traffic_weight': trafficWeight,
      if (lastObserved != null) 'last_observed': lastObserved,
      if (obsCount != null) 'obs_count': obsCount,
      if (source != null) 'source': source,
      if (importedSnr != null) 'imported_snr': importedSnr,
      if (importedObservations != null)
        'imported_observations': importedObservations,
      if (importedDelivered != null) 'imported_delivered': importedDelivered,
      if (importedAttempts != null) 'imported_attempts': importedAttempts,
      if (importedLastObserved != null)
        'imported_last_observed': importedLastObserved,
      if (measuredSnr != null) 'measured_snr': measuredSnr,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GraphEdgesCompanion copyWith(
      {Value<String>? fromHash,
      Value<String>? toHash,
      Value<int>? s,
      Value<int>? n,
      Value<double>? trafficWeight,
      Value<int?>? lastObserved,
      Value<int>? obsCount,
      Value<String>? source,
      Value<double?>? importedSnr,
      Value<int>? importedObservations,
      Value<int>? importedDelivered,
      Value<int>? importedAttempts,
      Value<int?>? importedLastObserved,
      Value<double?>? measuredSnr,
      Value<int>? rowid}) {
    return GraphEdgesCompanion(
      fromHash: fromHash ?? this.fromHash,
      toHash: toHash ?? this.toHash,
      s: s ?? this.s,
      n: n ?? this.n,
      trafficWeight: trafficWeight ?? this.trafficWeight,
      lastObserved: lastObserved ?? this.lastObserved,
      obsCount: obsCount ?? this.obsCount,
      source: source ?? this.source,
      importedSnr: importedSnr ?? this.importedSnr,
      importedObservations: importedObservations ?? this.importedObservations,
      importedDelivered: importedDelivered ?? this.importedDelivered,
      importedAttempts: importedAttempts ?? this.importedAttempts,
      importedLastObserved: importedLastObserved ?? this.importedLastObserved,
      measuredSnr: measuredSnr ?? this.measuredSnr,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromHash.present) {
      map['from_hash'] = Variable<String>(fromHash.value);
    }
    if (toHash.present) {
      map['to_hash'] = Variable<String>(toHash.value);
    }
    if (s.present) {
      map['s'] = Variable<int>(s.value);
    }
    if (n.present) {
      map['n'] = Variable<int>(n.value);
    }
    if (trafficWeight.present) {
      map['traffic_weight'] = Variable<double>(trafficWeight.value);
    }
    if (lastObserved.present) {
      map['last_observed'] = Variable<int>(lastObserved.value);
    }
    if (obsCount.present) {
      map['obs_count'] = Variable<int>(obsCount.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (importedSnr.present) {
      map['imported_snr'] = Variable<double>(importedSnr.value);
    }
    if (importedObservations.present) {
      map['imported_observations'] = Variable<int>(importedObservations.value);
    }
    if (importedDelivered.present) {
      map['imported_delivered'] = Variable<int>(importedDelivered.value);
    }
    if (importedAttempts.present) {
      map['imported_attempts'] = Variable<int>(importedAttempts.value);
    }
    if (importedLastObserved.present) {
      map['imported_last_observed'] = Variable<int>(importedLastObserved.value);
    }
    if (measuredSnr.present) {
      map['measured_snr'] = Variable<double>(measuredSnr.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GraphEdgesCompanion(')
          ..write('fromHash: $fromHash, ')
          ..write('toHash: $toHash, ')
          ..write('s: $s, ')
          ..write('n: $n, ')
          ..write('trafficWeight: $trafficWeight, ')
          ..write('lastObserved: $lastObserved, ')
          ..write('obsCount: $obsCount, ')
          ..write('source: $source, ')
          ..write('importedSnr: $importedSnr, ')
          ..write('importedObservations: $importedObservations, ')
          ..write('importedDelivered: $importedDelivered, ')
          ..write('importedAttempts: $importedAttempts, ')
          ..write('importedLastObserved: $importedLastObserved, ')
          ..write('measuredSnr: $measuredSnr, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactIngressTable extends ContactIngress
    with TableInfo<$ContactIngressTable, ContactIngressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactIngressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerPubkeyMeta =
      const VerificationMeta('ownerPubkey');
  @override
  late final GeneratedColumn<String> ownerPubkey = GeneratedColumn<String>(
      'owner_pubkey', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _repeaterHashMeta =
      const VerificationMeta('repeaterHash');
  @override
  late final GeneratedColumn<String> repeaterHash = GeneratedColumn<String>(
      'repeater_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lastSeenMeta =
      const VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<int> lastSeen = GeneratedColumn<int>(
      'last_seen', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _evidenceMeta =
      const VerificationMeta('evidence');
  @override
  late final GeneratedColumn<String> evidence = GeneratedColumn<String>(
      'evidence', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _observedLatMeta =
      const VerificationMeta('observedLat');
  @override
  late final GeneratedColumn<double> observedLat = GeneratedColumn<double>(
      'observed_lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _observedLonMeta =
      const VerificationMeta('observedLon');
  @override
  late final GeneratedColumn<double> observedLon = GeneratedColumn<double>(
      'observed_lon', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _uplinkSnrMeta =
      const VerificationMeta('uplinkSnr');
  @override
  late final GeneratedColumn<double> uplinkSnr = GeneratedColumn<double>(
      'uplink_snr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _downlinkSnrMeta =
      const VerificationMeta('downlinkSnr');
  @override
  late final GeneratedColumn<double> downlinkSnr = GeneratedColumn<double>(
      'downlink_snr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _finalCountMeta =
      const VerificationMeta('finalCount');
  @override
  late final GeneratedColumn<int> finalCount = GeneratedColumn<int>(
      'final_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _penultimateCountMeta =
      const VerificationMeta('penultimateCount');
  @override
  late final GeneratedColumn<int> penultimateCount = GeneratedColumn<int>(
      'penultimate_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        ownerPubkey,
        repeaterHash,
        weight,
        lastSeen,
        evidence,
        observedLat,
        observedLon,
        uplinkSnr,
        downlinkSnr,
        finalCount,
        penultimateCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_ingress';
  @override
  VerificationContext validateIntegrity(Insertable<ContactIngressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_pubkey')) {
      context.handle(
          _ownerPubkeyMeta,
          ownerPubkey.isAcceptableOrUnknown(
              data['owner_pubkey']!, _ownerPubkeyMeta));
    } else if (isInserting) {
      context.missing(_ownerPubkeyMeta);
    }
    if (data.containsKey('repeater_hash')) {
      context.handle(
          _repeaterHashMeta,
          repeaterHash.isAcceptableOrUnknown(
              data['repeater_hash']!, _repeaterHashMeta));
    } else if (isInserting) {
      context.missing(_repeaterHashMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('evidence')) {
      context.handle(_evidenceMeta,
          evidence.isAcceptableOrUnknown(data['evidence']!, _evidenceMeta));
    } else if (isInserting) {
      context.missing(_evidenceMeta);
    }
    if (data.containsKey('observed_lat')) {
      context.handle(
          _observedLatMeta,
          observedLat.isAcceptableOrUnknown(
              data['observed_lat']!, _observedLatMeta));
    }
    if (data.containsKey('observed_lon')) {
      context.handle(
          _observedLonMeta,
          observedLon.isAcceptableOrUnknown(
              data['observed_lon']!, _observedLonMeta));
    }
    if (data.containsKey('uplink_snr')) {
      context.handle(_uplinkSnrMeta,
          uplinkSnr.isAcceptableOrUnknown(data['uplink_snr']!, _uplinkSnrMeta));
    }
    if (data.containsKey('downlink_snr')) {
      context.handle(
          _downlinkSnrMeta,
          downlinkSnr.isAcceptableOrUnknown(
              data['downlink_snr']!, _downlinkSnrMeta));
    }
    if (data.containsKey('final_count')) {
      context.handle(
          _finalCountMeta,
          finalCount.isAcceptableOrUnknown(
              data['final_count']!, _finalCountMeta));
    }
    if (data.containsKey('penultimate_count')) {
      context.handle(
          _penultimateCountMeta,
          penultimateCount.isAcceptableOrUnknown(
              data['penultimate_count']!, _penultimateCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerPubkey, repeaterHash};
  @override
  ContactIngressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactIngressData(
      ownerPubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_pubkey'])!,
      repeaterHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repeater_hash'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      lastSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_seen'])!,
      evidence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}evidence'])!,
      observedLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}observed_lat']),
      observedLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}observed_lon']),
      uplinkSnr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}uplink_snr']),
      downlinkSnr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}downlink_snr']),
      finalCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}final_count'])!,
      penultimateCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}penultimate_count'])!,
    );
  }

  @override
  $ContactIngressTable createAlias(String alias) {
    return $ContactIngressTable(attachedDatabase, alias);
  }
}

class ContactIngressData extends DataClass
    implements Insertable<ContactIngressData> {
  final String ownerPubkey;
  final String repeaterHash;
  final double weight;
  final int lastSeen;
  final String evidence;
  final double? observedLat;
  final double? observedLon;

  /// Measured first-hop link, both directions (Discover): uplink = how
  /// well they heard US, downlink = how well we heard THEM.
  final double? uplinkSnr;
  final double? downlinkSnr;

  /// Self rows only: hub signature. A repeater that shows up second-to-
  /// last far more often than last is a hub I hear *through*, not a
  /// doorstep I can reach — the ratio demotes it.
  final int finalCount;
  final int penultimateCount;
  const ContactIngressData(
      {required this.ownerPubkey,
      required this.repeaterHash,
      required this.weight,
      required this.lastSeen,
      required this.evidence,
      this.observedLat,
      this.observedLon,
      this.uplinkSnr,
      this.downlinkSnr,
      required this.finalCount,
      required this.penultimateCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_pubkey'] = Variable<String>(ownerPubkey);
    map['repeater_hash'] = Variable<String>(repeaterHash);
    map['weight'] = Variable<double>(weight);
    map['last_seen'] = Variable<int>(lastSeen);
    map['evidence'] = Variable<String>(evidence);
    if (!nullToAbsent || observedLat != null) {
      map['observed_lat'] = Variable<double>(observedLat);
    }
    if (!nullToAbsent || observedLon != null) {
      map['observed_lon'] = Variable<double>(observedLon);
    }
    if (!nullToAbsent || uplinkSnr != null) {
      map['uplink_snr'] = Variable<double>(uplinkSnr);
    }
    if (!nullToAbsent || downlinkSnr != null) {
      map['downlink_snr'] = Variable<double>(downlinkSnr);
    }
    map['final_count'] = Variable<int>(finalCount);
    map['penultimate_count'] = Variable<int>(penultimateCount);
    return map;
  }

  ContactIngressCompanion toCompanion(bool nullToAbsent) {
    return ContactIngressCompanion(
      ownerPubkey: Value(ownerPubkey),
      repeaterHash: Value(repeaterHash),
      weight: Value(weight),
      lastSeen: Value(lastSeen),
      evidence: Value(evidence),
      observedLat: observedLat == null && nullToAbsent
          ? const Value.absent()
          : Value(observedLat),
      observedLon: observedLon == null && nullToAbsent
          ? const Value.absent()
          : Value(observedLon),
      uplinkSnr: uplinkSnr == null && nullToAbsent
          ? const Value.absent()
          : Value(uplinkSnr),
      downlinkSnr: downlinkSnr == null && nullToAbsent
          ? const Value.absent()
          : Value(downlinkSnr),
      finalCount: Value(finalCount),
      penultimateCount: Value(penultimateCount),
    );
  }

  factory ContactIngressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactIngressData(
      ownerPubkey: serializer.fromJson<String>(json['ownerPubkey']),
      repeaterHash: serializer.fromJson<String>(json['repeaterHash']),
      weight: serializer.fromJson<double>(json['weight']),
      lastSeen: serializer.fromJson<int>(json['lastSeen']),
      evidence: serializer.fromJson<String>(json['evidence']),
      observedLat: serializer.fromJson<double?>(json['observedLat']),
      observedLon: serializer.fromJson<double?>(json['observedLon']),
      uplinkSnr: serializer.fromJson<double?>(json['uplinkSnr']),
      downlinkSnr: serializer.fromJson<double?>(json['downlinkSnr']),
      finalCount: serializer.fromJson<int>(json['finalCount']),
      penultimateCount: serializer.fromJson<int>(json['penultimateCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerPubkey': serializer.toJson<String>(ownerPubkey),
      'repeaterHash': serializer.toJson<String>(repeaterHash),
      'weight': serializer.toJson<double>(weight),
      'lastSeen': serializer.toJson<int>(lastSeen),
      'evidence': serializer.toJson<String>(evidence),
      'observedLat': serializer.toJson<double?>(observedLat),
      'observedLon': serializer.toJson<double?>(observedLon),
      'uplinkSnr': serializer.toJson<double?>(uplinkSnr),
      'downlinkSnr': serializer.toJson<double?>(downlinkSnr),
      'finalCount': serializer.toJson<int>(finalCount),
      'penultimateCount': serializer.toJson<int>(penultimateCount),
    };
  }

  ContactIngressData copyWith(
          {String? ownerPubkey,
          String? repeaterHash,
          double? weight,
          int? lastSeen,
          String? evidence,
          Value<double?> observedLat = const Value.absent(),
          Value<double?> observedLon = const Value.absent(),
          Value<double?> uplinkSnr = const Value.absent(),
          Value<double?> downlinkSnr = const Value.absent(),
          int? finalCount,
          int? penultimateCount}) =>
      ContactIngressData(
        ownerPubkey: ownerPubkey ?? this.ownerPubkey,
        repeaterHash: repeaterHash ?? this.repeaterHash,
        weight: weight ?? this.weight,
        lastSeen: lastSeen ?? this.lastSeen,
        evidence: evidence ?? this.evidence,
        observedLat: observedLat.present ? observedLat.value : this.observedLat,
        observedLon: observedLon.present ? observedLon.value : this.observedLon,
        uplinkSnr: uplinkSnr.present ? uplinkSnr.value : this.uplinkSnr,
        downlinkSnr: downlinkSnr.present ? downlinkSnr.value : this.downlinkSnr,
        finalCount: finalCount ?? this.finalCount,
        penultimateCount: penultimateCount ?? this.penultimateCount,
      );
  ContactIngressData copyWithCompanion(ContactIngressCompanion data) {
    return ContactIngressData(
      ownerPubkey:
          data.ownerPubkey.present ? data.ownerPubkey.value : this.ownerPubkey,
      repeaterHash: data.repeaterHash.present
          ? data.repeaterHash.value
          : this.repeaterHash,
      weight: data.weight.present ? data.weight.value : this.weight,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      evidence: data.evidence.present ? data.evidence.value : this.evidence,
      observedLat:
          data.observedLat.present ? data.observedLat.value : this.observedLat,
      observedLon:
          data.observedLon.present ? data.observedLon.value : this.observedLon,
      uplinkSnr: data.uplinkSnr.present ? data.uplinkSnr.value : this.uplinkSnr,
      downlinkSnr:
          data.downlinkSnr.present ? data.downlinkSnr.value : this.downlinkSnr,
      finalCount:
          data.finalCount.present ? data.finalCount.value : this.finalCount,
      penultimateCount: data.penultimateCount.present
          ? data.penultimateCount.value
          : this.penultimateCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactIngressData(')
          ..write('ownerPubkey: $ownerPubkey, ')
          ..write('repeaterHash: $repeaterHash, ')
          ..write('weight: $weight, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('evidence: $evidence, ')
          ..write('observedLat: $observedLat, ')
          ..write('observedLon: $observedLon, ')
          ..write('uplinkSnr: $uplinkSnr, ')
          ..write('downlinkSnr: $downlinkSnr, ')
          ..write('finalCount: $finalCount, ')
          ..write('penultimateCount: $penultimateCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      ownerPubkey,
      repeaterHash,
      weight,
      lastSeen,
      evidence,
      observedLat,
      observedLon,
      uplinkSnr,
      downlinkSnr,
      finalCount,
      penultimateCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactIngressData &&
          other.ownerPubkey == this.ownerPubkey &&
          other.repeaterHash == this.repeaterHash &&
          other.weight == this.weight &&
          other.lastSeen == this.lastSeen &&
          other.evidence == this.evidence &&
          other.observedLat == this.observedLat &&
          other.observedLon == this.observedLon &&
          other.uplinkSnr == this.uplinkSnr &&
          other.downlinkSnr == this.downlinkSnr &&
          other.finalCount == this.finalCount &&
          other.penultimateCount == this.penultimateCount);
}

class ContactIngressCompanion extends UpdateCompanion<ContactIngressData> {
  final Value<String> ownerPubkey;
  final Value<String> repeaterHash;
  final Value<double> weight;
  final Value<int> lastSeen;
  final Value<String> evidence;
  final Value<double?> observedLat;
  final Value<double?> observedLon;
  final Value<double?> uplinkSnr;
  final Value<double?> downlinkSnr;
  final Value<int> finalCount;
  final Value<int> penultimateCount;
  final Value<int> rowid;
  const ContactIngressCompanion({
    this.ownerPubkey = const Value.absent(),
    this.repeaterHash = const Value.absent(),
    this.weight = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.evidence = const Value.absent(),
    this.observedLat = const Value.absent(),
    this.observedLon = const Value.absent(),
    this.uplinkSnr = const Value.absent(),
    this.downlinkSnr = const Value.absent(),
    this.finalCount = const Value.absent(),
    this.penultimateCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactIngressCompanion.insert({
    required String ownerPubkey,
    required String repeaterHash,
    required double weight,
    required int lastSeen,
    required String evidence,
    this.observedLat = const Value.absent(),
    this.observedLon = const Value.absent(),
    this.uplinkSnr = const Value.absent(),
    this.downlinkSnr = const Value.absent(),
    this.finalCount = const Value.absent(),
    this.penultimateCount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : ownerPubkey = Value(ownerPubkey),
        repeaterHash = Value(repeaterHash),
        weight = Value(weight),
        lastSeen = Value(lastSeen),
        evidence = Value(evidence);
  static Insertable<ContactIngressData> custom({
    Expression<String>? ownerPubkey,
    Expression<String>? repeaterHash,
    Expression<double>? weight,
    Expression<int>? lastSeen,
    Expression<String>? evidence,
    Expression<double>? observedLat,
    Expression<double>? observedLon,
    Expression<double>? uplinkSnr,
    Expression<double>? downlinkSnr,
    Expression<int>? finalCount,
    Expression<int>? penultimateCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerPubkey != null) 'owner_pubkey': ownerPubkey,
      if (repeaterHash != null) 'repeater_hash': repeaterHash,
      if (weight != null) 'weight': weight,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (evidence != null) 'evidence': evidence,
      if (observedLat != null) 'observed_lat': observedLat,
      if (observedLon != null) 'observed_lon': observedLon,
      if (uplinkSnr != null) 'uplink_snr': uplinkSnr,
      if (downlinkSnr != null) 'downlink_snr': downlinkSnr,
      if (finalCount != null) 'final_count': finalCount,
      if (penultimateCount != null) 'penultimate_count': penultimateCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactIngressCompanion copyWith(
      {Value<String>? ownerPubkey,
      Value<String>? repeaterHash,
      Value<double>? weight,
      Value<int>? lastSeen,
      Value<String>? evidence,
      Value<double?>? observedLat,
      Value<double?>? observedLon,
      Value<double?>? uplinkSnr,
      Value<double?>? downlinkSnr,
      Value<int>? finalCount,
      Value<int>? penultimateCount,
      Value<int>? rowid}) {
    return ContactIngressCompanion(
      ownerPubkey: ownerPubkey ?? this.ownerPubkey,
      repeaterHash: repeaterHash ?? this.repeaterHash,
      weight: weight ?? this.weight,
      lastSeen: lastSeen ?? this.lastSeen,
      evidence: evidence ?? this.evidence,
      observedLat: observedLat ?? this.observedLat,
      observedLon: observedLon ?? this.observedLon,
      uplinkSnr: uplinkSnr ?? this.uplinkSnr,
      downlinkSnr: downlinkSnr ?? this.downlinkSnr,
      finalCount: finalCount ?? this.finalCount,
      penultimateCount: penultimateCount ?? this.penultimateCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerPubkey.present) {
      map['owner_pubkey'] = Variable<String>(ownerPubkey.value);
    }
    if (repeaterHash.present) {
      map['repeater_hash'] = Variable<String>(repeaterHash.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<int>(lastSeen.value);
    }
    if (evidence.present) {
      map['evidence'] = Variable<String>(evidence.value);
    }
    if (observedLat.present) {
      map['observed_lat'] = Variable<double>(observedLat.value);
    }
    if (observedLon.present) {
      map['observed_lon'] = Variable<double>(observedLon.value);
    }
    if (uplinkSnr.present) {
      map['uplink_snr'] = Variable<double>(uplinkSnr.value);
    }
    if (downlinkSnr.present) {
      map['downlink_snr'] = Variable<double>(downlinkSnr.value);
    }
    if (finalCount.present) {
      map['final_count'] = Variable<int>(finalCount.value);
    }
    if (penultimateCount.present) {
      map['penultimate_count'] = Variable<int>(penultimateCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactIngressCompanion(')
          ..write('ownerPubkey: $ownerPubkey, ')
          ..write('repeaterHash: $repeaterHash, ')
          ..write('weight: $weight, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('evidence: $evidence, ')
          ..write('observedLat: $observedLat, ')
          ..write('observedLon: $observedLon, ')
          ..write('uplinkSnr: $uplinkSnr, ')
          ..write('downlinkSnr: $downlinkSnr, ')
          ..write('finalCount: $finalCount, ')
          ..write('penultimateCount: $penultimateCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KnownContactsTable extends KnownContacts
    with TableInfo<$KnownContactsTable, KnownContact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnownContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contactPubkeyMeta =
      const VerificationMeta('contactPubkey');
  @override
  late final GeneratedColumn<String> contactPubkey = GeneratedColumn<String>(
      'contact_pubkey', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastKnownLatMeta =
      const VerificationMeta('lastKnownLat');
  @override
  late final GeneratedColumn<double> lastKnownLat = GeneratedColumn<double>(
      'last_known_lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lastKnownLonMeta =
      const VerificationMeta('lastKnownLon');
  @override
  late final GeneratedColumn<double> lastKnownLon = GeneratedColumn<double>(
      'last_known_lon', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lastRefreshedMeta =
      const VerificationMeta('lastRefreshed');
  @override
  late final GeneratedColumn<int> lastRefreshed = GeneratedColumn<int>(
      'last_refreshed', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [contactPubkey, name, lastKnownLat, lastKnownLon, lastRefreshed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'known_contacts';
  @override
  VerificationContext validateIntegrity(Insertable<KnownContact> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contact_pubkey')) {
      context.handle(
          _contactPubkeyMeta,
          contactPubkey.isAcceptableOrUnknown(
              data['contact_pubkey']!, _contactPubkeyMeta));
    } else if (isInserting) {
      context.missing(_contactPubkeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('last_known_lat')) {
      context.handle(
          _lastKnownLatMeta,
          lastKnownLat.isAcceptableOrUnknown(
              data['last_known_lat']!, _lastKnownLatMeta));
    }
    if (data.containsKey('last_known_lon')) {
      context.handle(
          _lastKnownLonMeta,
          lastKnownLon.isAcceptableOrUnknown(
              data['last_known_lon']!, _lastKnownLonMeta));
    }
    if (data.containsKey('last_refreshed')) {
      context.handle(
          _lastRefreshedMeta,
          lastRefreshed.isAcceptableOrUnknown(
              data['last_refreshed']!, _lastRefreshedMeta));
    } else if (isInserting) {
      context.missing(_lastRefreshedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contactPubkey};
  @override
  KnownContact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnownContact(
      contactPubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_pubkey'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      lastKnownLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}last_known_lat']),
      lastKnownLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}last_known_lon']),
      lastRefreshed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_refreshed'])!,
    );
  }

  @override
  $KnownContactsTable createAlias(String alias) {
    return $KnownContactsTable(attachedDatabase, alias);
  }
}

class KnownContact extends DataClass implements Insertable<KnownContact> {
  final String contactPubkey;
  final String name;
  final double? lastKnownLat;
  final double? lastKnownLon;
  final int lastRefreshed;
  const KnownContact(
      {required this.contactPubkey,
      required this.name,
      this.lastKnownLat,
      this.lastKnownLon,
      required this.lastRefreshed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contact_pubkey'] = Variable<String>(contactPubkey);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || lastKnownLat != null) {
      map['last_known_lat'] = Variable<double>(lastKnownLat);
    }
    if (!nullToAbsent || lastKnownLon != null) {
      map['last_known_lon'] = Variable<double>(lastKnownLon);
    }
    map['last_refreshed'] = Variable<int>(lastRefreshed);
    return map;
  }

  KnownContactsCompanion toCompanion(bool nullToAbsent) {
    return KnownContactsCompanion(
      contactPubkey: Value(contactPubkey),
      name: Value(name),
      lastKnownLat: lastKnownLat == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownLat),
      lastKnownLon: lastKnownLon == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownLon),
      lastRefreshed: Value(lastRefreshed),
    );
  }

  factory KnownContact.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnownContact(
      contactPubkey: serializer.fromJson<String>(json['contactPubkey']),
      name: serializer.fromJson<String>(json['name']),
      lastKnownLat: serializer.fromJson<double?>(json['lastKnownLat']),
      lastKnownLon: serializer.fromJson<double?>(json['lastKnownLon']),
      lastRefreshed: serializer.fromJson<int>(json['lastRefreshed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contactPubkey': serializer.toJson<String>(contactPubkey),
      'name': serializer.toJson<String>(name),
      'lastKnownLat': serializer.toJson<double?>(lastKnownLat),
      'lastKnownLon': serializer.toJson<double?>(lastKnownLon),
      'lastRefreshed': serializer.toJson<int>(lastRefreshed),
    };
  }

  KnownContact copyWith(
          {String? contactPubkey,
          String? name,
          Value<double?> lastKnownLat = const Value.absent(),
          Value<double?> lastKnownLon = const Value.absent(),
          int? lastRefreshed}) =>
      KnownContact(
        contactPubkey: contactPubkey ?? this.contactPubkey,
        name: name ?? this.name,
        lastKnownLat:
            lastKnownLat.present ? lastKnownLat.value : this.lastKnownLat,
        lastKnownLon:
            lastKnownLon.present ? lastKnownLon.value : this.lastKnownLon,
        lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      );
  KnownContact copyWithCompanion(KnownContactsCompanion data) {
    return KnownContact(
      contactPubkey: data.contactPubkey.present
          ? data.contactPubkey.value
          : this.contactPubkey,
      name: data.name.present ? data.name.value : this.name,
      lastKnownLat: data.lastKnownLat.present
          ? data.lastKnownLat.value
          : this.lastKnownLat,
      lastKnownLon: data.lastKnownLon.present
          ? data.lastKnownLon.value
          : this.lastKnownLon,
      lastRefreshed: data.lastRefreshed.present
          ? data.lastRefreshed.value
          : this.lastRefreshed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnownContact(')
          ..write('contactPubkey: $contactPubkey, ')
          ..write('name: $name, ')
          ..write('lastKnownLat: $lastKnownLat, ')
          ..write('lastKnownLon: $lastKnownLon, ')
          ..write('lastRefreshed: $lastRefreshed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      contactPubkey, name, lastKnownLat, lastKnownLon, lastRefreshed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnownContact &&
          other.contactPubkey == this.contactPubkey &&
          other.name == this.name &&
          other.lastKnownLat == this.lastKnownLat &&
          other.lastKnownLon == this.lastKnownLon &&
          other.lastRefreshed == this.lastRefreshed);
}

class KnownContactsCompanion extends UpdateCompanion<KnownContact> {
  final Value<String> contactPubkey;
  final Value<String> name;
  final Value<double?> lastKnownLat;
  final Value<double?> lastKnownLon;
  final Value<int> lastRefreshed;
  final Value<int> rowid;
  const KnownContactsCompanion({
    this.contactPubkey = const Value.absent(),
    this.name = const Value.absent(),
    this.lastKnownLat = const Value.absent(),
    this.lastKnownLon = const Value.absent(),
    this.lastRefreshed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnownContactsCompanion.insert({
    required String contactPubkey,
    required String name,
    this.lastKnownLat = const Value.absent(),
    this.lastKnownLon = const Value.absent(),
    required int lastRefreshed,
    this.rowid = const Value.absent(),
  })  : contactPubkey = Value(contactPubkey),
        name = Value(name),
        lastRefreshed = Value(lastRefreshed);
  static Insertable<KnownContact> custom({
    Expression<String>? contactPubkey,
    Expression<String>? name,
    Expression<double>? lastKnownLat,
    Expression<double>? lastKnownLon,
    Expression<int>? lastRefreshed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contactPubkey != null) 'contact_pubkey': contactPubkey,
      if (name != null) 'name': name,
      if (lastKnownLat != null) 'last_known_lat': lastKnownLat,
      if (lastKnownLon != null) 'last_known_lon': lastKnownLon,
      if (lastRefreshed != null) 'last_refreshed': lastRefreshed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnownContactsCompanion copyWith(
      {Value<String>? contactPubkey,
      Value<String>? name,
      Value<double?>? lastKnownLat,
      Value<double?>? lastKnownLon,
      Value<int>? lastRefreshed,
      Value<int>? rowid}) {
    return KnownContactsCompanion(
      contactPubkey: contactPubkey ?? this.contactPubkey,
      name: name ?? this.name,
      lastKnownLat: lastKnownLat ?? this.lastKnownLat,
      lastKnownLon: lastKnownLon ?? this.lastKnownLon,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contactPubkey.present) {
      map['contact_pubkey'] = Variable<String>(contactPubkey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lastKnownLat.present) {
      map['last_known_lat'] = Variable<double>(lastKnownLat.value);
    }
    if (lastKnownLon.present) {
      map['last_known_lon'] = Variable<double>(lastKnownLon.value);
    }
    if (lastRefreshed.present) {
      map['last_refreshed'] = Variable<int>(lastRefreshed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnownContactsCompanion(')
          ..write('contactPubkey: $contactPubkey, ')
          ..write('name: $name, ')
          ..write('lastKnownLat: $lastKnownLat, ')
          ..write('lastKnownLon: $lastKnownLon, ')
          ..write('lastRefreshed: $lastRefreshed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GraphMetaTable extends GraphMeta
    with TableInfo<$GraphMetaTable, GraphMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraphMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'graph_meta';
  @override
  VerificationContext validateIntegrity(Insertable<GraphMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  GraphMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraphMetaData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $GraphMetaTable createAlias(String alias) {
    return $GraphMetaTable(attachedDatabase, alias);
  }
}

class GraphMetaData extends DataClass implements Insertable<GraphMetaData> {
  final String key;
  final String value;
  const GraphMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  GraphMetaCompanion toCompanion(bool nullToAbsent) {
    return GraphMetaCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory GraphMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraphMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  GraphMetaData copyWith({String? key, String? value}) => GraphMetaData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  GraphMetaData copyWithCompanion(GraphMetaCompanion data) {
    return GraphMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraphMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraphMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class GraphMetaCompanion extends UpdateCompanion<GraphMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const GraphMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GraphMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<GraphMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GraphMetaCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return GraphMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GraphMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$PathGraphDatabase extends GeneratedDatabase {
  _$PathGraphDatabase(QueryExecutor e) : super(e);
  $PathGraphDatabaseManager get managers => $PathGraphDatabaseManager(this);
  late final $GraphNodesTable graphNodes = $GraphNodesTable(this);
  late final $GraphEdgesTable graphEdges = $GraphEdgesTable(this);
  late final $ContactIngressTable contactIngress = $ContactIngressTable(this);
  late final $KnownContactsTable knownContacts = $KnownContactsTable(this);
  late final $GraphMetaTable graphMeta = $GraphMetaTable(this);
  late final Index idxEdgesFrom = Index('idx_edges_from',
      'CREATE INDEX idx_edges_from ON graph_edges (from_hash)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        graphNodes,
        graphEdges,
        contactIngress,
        knownContacts,
        graphMeta,
        idxEdgesFrom
      ];
}

typedef $$GraphNodesTableCreateCompanionBuilder = GraphNodesCompanion Function({
  required String hashBytes,
  Value<String?> name,
  Value<String?> role,
  Value<double?> lat,
  Value<double?> lon,
  Value<int?> lastHeard,
  required String source,
  Value<String?> region,
  Value<String?> pubkey,
  Value<int> rowid,
});
typedef $$GraphNodesTableUpdateCompanionBuilder = GraphNodesCompanion Function({
  Value<String> hashBytes,
  Value<String?> name,
  Value<String?> role,
  Value<double?> lat,
  Value<double?> lon,
  Value<int?> lastHeard,
  Value<String> source,
  Value<String?> region,
  Value<String?> pubkey,
  Value<int> rowid,
});

class $$GraphNodesTableFilterComposer
    extends Composer<_$PathGraphDatabase, $GraphNodesTable> {
  $$GraphNodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get hashBytes => $composableBuilder(
      column: $table.hashBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastHeard => $composableBuilder(
      column: $table.lastHeard, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pubkey => $composableBuilder(
      column: $table.pubkey, builder: (column) => ColumnFilters(column));
}

class $$GraphNodesTableOrderingComposer
    extends Composer<_$PathGraphDatabase, $GraphNodesTable> {
  $$GraphNodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get hashBytes => $composableBuilder(
      column: $table.hashBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastHeard => $composableBuilder(
      column: $table.lastHeard, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pubkey => $composableBuilder(
      column: $table.pubkey, builder: (column) => ColumnOrderings(column));
}

class $$GraphNodesTableAnnotationComposer
    extends Composer<_$PathGraphDatabase, $GraphNodesTable> {
  $$GraphNodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get hashBytes =>
      $composableBuilder(column: $table.hashBytes, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<int> get lastHeard =>
      $composableBuilder(column: $table.lastHeard, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);
}

class $$GraphNodesTableTableManager extends RootTableManager<
    _$PathGraphDatabase,
    $GraphNodesTable,
    GraphNode,
    $$GraphNodesTableFilterComposer,
    $$GraphNodesTableOrderingComposer,
    $$GraphNodesTableAnnotationComposer,
    $$GraphNodesTableCreateCompanionBuilder,
    $$GraphNodesTableUpdateCompanionBuilder,
    (
      GraphNode,
      BaseReferences<_$PathGraphDatabase, $GraphNodesTable, GraphNode>
    ),
    GraphNode,
    PrefetchHooks Function()> {
  $$GraphNodesTableTableManager(_$PathGraphDatabase db, $GraphNodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GraphNodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GraphNodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GraphNodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> hashBytes = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> role = const Value.absent(),
            Value<double?> lat = const Value.absent(),
            Value<double?> lon = const Value.absent(),
            Value<int?> lastHeard = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> region = const Value.absent(),
            Value<String?> pubkey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GraphNodesCompanion(
            hashBytes: hashBytes,
            name: name,
            role: role,
            lat: lat,
            lon: lon,
            lastHeard: lastHeard,
            source: source,
            region: region,
            pubkey: pubkey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String hashBytes,
            Value<String?> name = const Value.absent(),
            Value<String?> role = const Value.absent(),
            Value<double?> lat = const Value.absent(),
            Value<double?> lon = const Value.absent(),
            Value<int?> lastHeard = const Value.absent(),
            required String source,
            Value<String?> region = const Value.absent(),
            Value<String?> pubkey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GraphNodesCompanion.insert(
            hashBytes: hashBytes,
            name: name,
            role: role,
            lat: lat,
            lon: lon,
            lastHeard: lastHeard,
            source: source,
            region: region,
            pubkey: pubkey,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GraphNodesTableProcessedTableManager = ProcessedTableManager<
    _$PathGraphDatabase,
    $GraphNodesTable,
    GraphNode,
    $$GraphNodesTableFilterComposer,
    $$GraphNodesTableOrderingComposer,
    $$GraphNodesTableAnnotationComposer,
    $$GraphNodesTableCreateCompanionBuilder,
    $$GraphNodesTableUpdateCompanionBuilder,
    (
      GraphNode,
      BaseReferences<_$PathGraphDatabase, $GraphNodesTable, GraphNode>
    ),
    GraphNode,
    PrefetchHooks Function()>;
typedef $$GraphEdgesTableCreateCompanionBuilder = GraphEdgesCompanion Function({
  required String fromHash,
  required String toHash,
  Value<int> s,
  Value<int> n,
  Value<double> trafficWeight,
  Value<int?> lastObserved,
  Value<int> obsCount,
  required String source,
  Value<double?> importedSnr,
  Value<int> importedObservations,
  Value<int> importedDelivered,
  Value<int> importedAttempts,
  Value<int?> importedLastObserved,
  Value<double?> measuredSnr,
  Value<int> rowid,
});
typedef $$GraphEdgesTableUpdateCompanionBuilder = GraphEdgesCompanion Function({
  Value<String> fromHash,
  Value<String> toHash,
  Value<int> s,
  Value<int> n,
  Value<double> trafficWeight,
  Value<int?> lastObserved,
  Value<int> obsCount,
  Value<String> source,
  Value<double?> importedSnr,
  Value<int> importedObservations,
  Value<int> importedDelivered,
  Value<int> importedAttempts,
  Value<int?> importedLastObserved,
  Value<double?> measuredSnr,
  Value<int> rowid,
});

class $$GraphEdgesTableFilterComposer
    extends Composer<_$PathGraphDatabase, $GraphEdgesTable> {
  $$GraphEdgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fromHash => $composableBuilder(
      column: $table.fromHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toHash => $composableBuilder(
      column: $table.toHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get s => $composableBuilder(
      column: $table.s, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get n => $composableBuilder(
      column: $table.n, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get trafficWeight => $composableBuilder(
      column: $table.trafficWeight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastObserved => $composableBuilder(
      column: $table.lastObserved, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get obsCount => $composableBuilder(
      column: $table.obsCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get importedSnr => $composableBuilder(
      column: $table.importedSnr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importedObservations => $composableBuilder(
      column: $table.importedObservations,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importedDelivered => $composableBuilder(
      column: $table.importedDelivered,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importedAttempts => $composableBuilder(
      column: $table.importedAttempts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importedLastObserved => $composableBuilder(
      column: $table.importedLastObserved,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get measuredSnr => $composableBuilder(
      column: $table.measuredSnr, builder: (column) => ColumnFilters(column));
}

class $$GraphEdgesTableOrderingComposer
    extends Composer<_$PathGraphDatabase, $GraphEdgesTable> {
  $$GraphEdgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fromHash => $composableBuilder(
      column: $table.fromHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toHash => $composableBuilder(
      column: $table.toHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get s => $composableBuilder(
      column: $table.s, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get n => $composableBuilder(
      column: $table.n, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get trafficWeight => $composableBuilder(
      column: $table.trafficWeight,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastObserved => $composableBuilder(
      column: $table.lastObserved,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get obsCount => $composableBuilder(
      column: $table.obsCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get importedSnr => $composableBuilder(
      column: $table.importedSnr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importedObservations => $composableBuilder(
      column: $table.importedObservations,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importedDelivered => $composableBuilder(
      column: $table.importedDelivered,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importedAttempts => $composableBuilder(
      column: $table.importedAttempts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importedLastObserved => $composableBuilder(
      column: $table.importedLastObserved,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get measuredSnr => $composableBuilder(
      column: $table.measuredSnr, builder: (column) => ColumnOrderings(column));
}

class $$GraphEdgesTableAnnotationComposer
    extends Composer<_$PathGraphDatabase, $GraphEdgesTable> {
  $$GraphEdgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fromHash =>
      $composableBuilder(column: $table.fromHash, builder: (column) => column);

  GeneratedColumn<String> get toHash =>
      $composableBuilder(column: $table.toHash, builder: (column) => column);

  GeneratedColumn<int> get s =>
      $composableBuilder(column: $table.s, builder: (column) => column);

  GeneratedColumn<int> get n =>
      $composableBuilder(column: $table.n, builder: (column) => column);

  GeneratedColumn<double> get trafficWeight => $composableBuilder(
      column: $table.trafficWeight, builder: (column) => column);

  GeneratedColumn<int> get lastObserved => $composableBuilder(
      column: $table.lastObserved, builder: (column) => column);

  GeneratedColumn<int> get obsCount =>
      $composableBuilder(column: $table.obsCount, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get importedSnr => $composableBuilder(
      column: $table.importedSnr, builder: (column) => column);

  GeneratedColumn<int> get importedObservations => $composableBuilder(
      column: $table.importedObservations, builder: (column) => column);

  GeneratedColumn<int> get importedDelivered => $composableBuilder(
      column: $table.importedDelivered, builder: (column) => column);

  GeneratedColumn<int> get importedAttempts => $composableBuilder(
      column: $table.importedAttempts, builder: (column) => column);

  GeneratedColumn<int> get importedLastObserved => $composableBuilder(
      column: $table.importedLastObserved, builder: (column) => column);

  GeneratedColumn<double> get measuredSnr => $composableBuilder(
      column: $table.measuredSnr, builder: (column) => column);
}

class $$GraphEdgesTableTableManager extends RootTableManager<
    _$PathGraphDatabase,
    $GraphEdgesTable,
    GraphEdge,
    $$GraphEdgesTableFilterComposer,
    $$GraphEdgesTableOrderingComposer,
    $$GraphEdgesTableAnnotationComposer,
    $$GraphEdgesTableCreateCompanionBuilder,
    $$GraphEdgesTableUpdateCompanionBuilder,
    (
      GraphEdge,
      BaseReferences<_$PathGraphDatabase, $GraphEdgesTable, GraphEdge>
    ),
    GraphEdge,
    PrefetchHooks Function()> {
  $$GraphEdgesTableTableManager(_$PathGraphDatabase db, $GraphEdgesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GraphEdgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GraphEdgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GraphEdgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> fromHash = const Value.absent(),
            Value<String> toHash = const Value.absent(),
            Value<int> s = const Value.absent(),
            Value<int> n = const Value.absent(),
            Value<double> trafficWeight = const Value.absent(),
            Value<int?> lastObserved = const Value.absent(),
            Value<int> obsCount = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<double?> importedSnr = const Value.absent(),
            Value<int> importedObservations = const Value.absent(),
            Value<int> importedDelivered = const Value.absent(),
            Value<int> importedAttempts = const Value.absent(),
            Value<int?> importedLastObserved = const Value.absent(),
            Value<double?> measuredSnr = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GraphEdgesCompanion(
            fromHash: fromHash,
            toHash: toHash,
            s: s,
            n: n,
            trafficWeight: trafficWeight,
            lastObserved: lastObserved,
            obsCount: obsCount,
            source: source,
            importedSnr: importedSnr,
            importedObservations: importedObservations,
            importedDelivered: importedDelivered,
            importedAttempts: importedAttempts,
            importedLastObserved: importedLastObserved,
            measuredSnr: measuredSnr,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String fromHash,
            required String toHash,
            Value<int> s = const Value.absent(),
            Value<int> n = const Value.absent(),
            Value<double> trafficWeight = const Value.absent(),
            Value<int?> lastObserved = const Value.absent(),
            Value<int> obsCount = const Value.absent(),
            required String source,
            Value<double?> importedSnr = const Value.absent(),
            Value<int> importedObservations = const Value.absent(),
            Value<int> importedDelivered = const Value.absent(),
            Value<int> importedAttempts = const Value.absent(),
            Value<int?> importedLastObserved = const Value.absent(),
            Value<double?> measuredSnr = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GraphEdgesCompanion.insert(
            fromHash: fromHash,
            toHash: toHash,
            s: s,
            n: n,
            trafficWeight: trafficWeight,
            lastObserved: lastObserved,
            obsCount: obsCount,
            source: source,
            importedSnr: importedSnr,
            importedObservations: importedObservations,
            importedDelivered: importedDelivered,
            importedAttempts: importedAttempts,
            importedLastObserved: importedLastObserved,
            measuredSnr: measuredSnr,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GraphEdgesTableProcessedTableManager = ProcessedTableManager<
    _$PathGraphDatabase,
    $GraphEdgesTable,
    GraphEdge,
    $$GraphEdgesTableFilterComposer,
    $$GraphEdgesTableOrderingComposer,
    $$GraphEdgesTableAnnotationComposer,
    $$GraphEdgesTableCreateCompanionBuilder,
    $$GraphEdgesTableUpdateCompanionBuilder,
    (
      GraphEdge,
      BaseReferences<_$PathGraphDatabase, $GraphEdgesTable, GraphEdge>
    ),
    GraphEdge,
    PrefetchHooks Function()>;
typedef $$ContactIngressTableCreateCompanionBuilder = ContactIngressCompanion
    Function({
  required String ownerPubkey,
  required String repeaterHash,
  required double weight,
  required int lastSeen,
  required String evidence,
  Value<double?> observedLat,
  Value<double?> observedLon,
  Value<double?> uplinkSnr,
  Value<double?> downlinkSnr,
  Value<int> finalCount,
  Value<int> penultimateCount,
  Value<int> rowid,
});
typedef $$ContactIngressTableUpdateCompanionBuilder = ContactIngressCompanion
    Function({
  Value<String> ownerPubkey,
  Value<String> repeaterHash,
  Value<double> weight,
  Value<int> lastSeen,
  Value<String> evidence,
  Value<double?> observedLat,
  Value<double?> observedLon,
  Value<double?> uplinkSnr,
  Value<double?> downlinkSnr,
  Value<int> finalCount,
  Value<int> penultimateCount,
  Value<int> rowid,
});

class $$ContactIngressTableFilterComposer
    extends Composer<_$PathGraphDatabase, $ContactIngressTable> {
  $$ContactIngressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerPubkey => $composableBuilder(
      column: $table.ownerPubkey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repeaterHash => $composableBuilder(
      column: $table.repeaterHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evidence => $composableBuilder(
      column: $table.evidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get observedLat => $composableBuilder(
      column: $table.observedLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get observedLon => $composableBuilder(
      column: $table.observedLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get uplinkSnr => $composableBuilder(
      column: $table.uplinkSnr, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get downlinkSnr => $composableBuilder(
      column: $table.downlinkSnr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get finalCount => $composableBuilder(
      column: $table.finalCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get penultimateCount => $composableBuilder(
      column: $table.penultimateCount,
      builder: (column) => ColumnFilters(column));
}

class $$ContactIngressTableOrderingComposer
    extends Composer<_$PathGraphDatabase, $ContactIngressTable> {
  $$ContactIngressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerPubkey => $composableBuilder(
      column: $table.ownerPubkey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeaterHash => $composableBuilder(
      column: $table.repeaterHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evidence => $composableBuilder(
      column: $table.evidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get observedLat => $composableBuilder(
      column: $table.observedLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get observedLon => $composableBuilder(
      column: $table.observedLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get uplinkSnr => $composableBuilder(
      column: $table.uplinkSnr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get downlinkSnr => $composableBuilder(
      column: $table.downlinkSnr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get finalCount => $composableBuilder(
      column: $table.finalCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get penultimateCount => $composableBuilder(
      column: $table.penultimateCount,
      builder: (column) => ColumnOrderings(column));
}

class $$ContactIngressTableAnnotationComposer
    extends Composer<_$PathGraphDatabase, $ContactIngressTable> {
  $$ContactIngressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerPubkey => $composableBuilder(
      column: $table.ownerPubkey, builder: (column) => column);

  GeneratedColumn<String> get repeaterHash => $composableBuilder(
      column: $table.repeaterHash, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<String> get evidence =>
      $composableBuilder(column: $table.evidence, builder: (column) => column);

  GeneratedColumn<double> get observedLat => $composableBuilder(
      column: $table.observedLat, builder: (column) => column);

  GeneratedColumn<double> get observedLon => $composableBuilder(
      column: $table.observedLon, builder: (column) => column);

  GeneratedColumn<double> get uplinkSnr =>
      $composableBuilder(column: $table.uplinkSnr, builder: (column) => column);

  GeneratedColumn<double> get downlinkSnr => $composableBuilder(
      column: $table.downlinkSnr, builder: (column) => column);

  GeneratedColumn<int> get finalCount => $composableBuilder(
      column: $table.finalCount, builder: (column) => column);

  GeneratedColumn<int> get penultimateCount => $composableBuilder(
      column: $table.penultimateCount, builder: (column) => column);
}

class $$ContactIngressTableTableManager extends RootTableManager<
    _$PathGraphDatabase,
    $ContactIngressTable,
    ContactIngressData,
    $$ContactIngressTableFilterComposer,
    $$ContactIngressTableOrderingComposer,
    $$ContactIngressTableAnnotationComposer,
    $$ContactIngressTableCreateCompanionBuilder,
    $$ContactIngressTableUpdateCompanionBuilder,
    (
      ContactIngressData,
      BaseReferences<_$PathGraphDatabase, $ContactIngressTable,
          ContactIngressData>
    ),
    ContactIngressData,
    PrefetchHooks Function()> {
  $$ContactIngressTableTableManager(
      _$PathGraphDatabase db, $ContactIngressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactIngressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactIngressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactIngressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> ownerPubkey = const Value.absent(),
            Value<String> repeaterHash = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<int> lastSeen = const Value.absent(),
            Value<String> evidence = const Value.absent(),
            Value<double?> observedLat = const Value.absent(),
            Value<double?> observedLon = const Value.absent(),
            Value<double?> uplinkSnr = const Value.absent(),
            Value<double?> downlinkSnr = const Value.absent(),
            Value<int> finalCount = const Value.absent(),
            Value<int> penultimateCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactIngressCompanion(
            ownerPubkey: ownerPubkey,
            repeaterHash: repeaterHash,
            weight: weight,
            lastSeen: lastSeen,
            evidence: evidence,
            observedLat: observedLat,
            observedLon: observedLon,
            uplinkSnr: uplinkSnr,
            downlinkSnr: downlinkSnr,
            finalCount: finalCount,
            penultimateCount: penultimateCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String ownerPubkey,
            required String repeaterHash,
            required double weight,
            required int lastSeen,
            required String evidence,
            Value<double?> observedLat = const Value.absent(),
            Value<double?> observedLon = const Value.absent(),
            Value<double?> uplinkSnr = const Value.absent(),
            Value<double?> downlinkSnr = const Value.absent(),
            Value<int> finalCount = const Value.absent(),
            Value<int> penultimateCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactIngressCompanion.insert(
            ownerPubkey: ownerPubkey,
            repeaterHash: repeaterHash,
            weight: weight,
            lastSeen: lastSeen,
            evidence: evidence,
            observedLat: observedLat,
            observedLon: observedLon,
            uplinkSnr: uplinkSnr,
            downlinkSnr: downlinkSnr,
            finalCount: finalCount,
            penultimateCount: penultimateCount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ContactIngressTableProcessedTableManager = ProcessedTableManager<
    _$PathGraphDatabase,
    $ContactIngressTable,
    ContactIngressData,
    $$ContactIngressTableFilterComposer,
    $$ContactIngressTableOrderingComposer,
    $$ContactIngressTableAnnotationComposer,
    $$ContactIngressTableCreateCompanionBuilder,
    $$ContactIngressTableUpdateCompanionBuilder,
    (
      ContactIngressData,
      BaseReferences<_$PathGraphDatabase, $ContactIngressTable,
          ContactIngressData>
    ),
    ContactIngressData,
    PrefetchHooks Function()>;
typedef $$KnownContactsTableCreateCompanionBuilder = KnownContactsCompanion
    Function({
  required String contactPubkey,
  required String name,
  Value<double?> lastKnownLat,
  Value<double?> lastKnownLon,
  required int lastRefreshed,
  Value<int> rowid,
});
typedef $$KnownContactsTableUpdateCompanionBuilder = KnownContactsCompanion
    Function({
  Value<String> contactPubkey,
  Value<String> name,
  Value<double?> lastKnownLat,
  Value<double?> lastKnownLon,
  Value<int> lastRefreshed,
  Value<int> rowid,
});

class $$KnownContactsTableFilterComposer
    extends Composer<_$PathGraphDatabase, $KnownContactsTable> {
  $$KnownContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contactPubkey => $composableBuilder(
      column: $table.contactPubkey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lastKnownLat => $composableBuilder(
      column: $table.lastKnownLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lastKnownLon => $composableBuilder(
      column: $table.lastKnownLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastRefreshed => $composableBuilder(
      column: $table.lastRefreshed, builder: (column) => ColumnFilters(column));
}

class $$KnownContactsTableOrderingComposer
    extends Composer<_$PathGraphDatabase, $KnownContactsTable> {
  $$KnownContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contactPubkey => $composableBuilder(
      column: $table.contactPubkey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lastKnownLat => $composableBuilder(
      column: $table.lastKnownLat,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lastKnownLon => $composableBuilder(
      column: $table.lastKnownLon,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastRefreshed => $composableBuilder(
      column: $table.lastRefreshed,
      builder: (column) => ColumnOrderings(column));
}

class $$KnownContactsTableAnnotationComposer
    extends Composer<_$PathGraphDatabase, $KnownContactsTable> {
  $$KnownContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contactPubkey => $composableBuilder(
      column: $table.contactPubkey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get lastKnownLat => $composableBuilder(
      column: $table.lastKnownLat, builder: (column) => column);

  GeneratedColumn<double> get lastKnownLon => $composableBuilder(
      column: $table.lastKnownLon, builder: (column) => column);

  GeneratedColumn<int> get lastRefreshed => $composableBuilder(
      column: $table.lastRefreshed, builder: (column) => column);
}

class $$KnownContactsTableTableManager extends RootTableManager<
    _$PathGraphDatabase,
    $KnownContactsTable,
    KnownContact,
    $$KnownContactsTableFilterComposer,
    $$KnownContactsTableOrderingComposer,
    $$KnownContactsTableAnnotationComposer,
    $$KnownContactsTableCreateCompanionBuilder,
    $$KnownContactsTableUpdateCompanionBuilder,
    (
      KnownContact,
      BaseReferences<_$PathGraphDatabase, $KnownContactsTable, KnownContact>
    ),
    KnownContact,
    PrefetchHooks Function()> {
  $$KnownContactsTableTableManager(
      _$PathGraphDatabase db, $KnownContactsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnownContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnownContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnownContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> contactPubkey = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double?> lastKnownLat = const Value.absent(),
            Value<double?> lastKnownLon = const Value.absent(),
            Value<int> lastRefreshed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KnownContactsCompanion(
            contactPubkey: contactPubkey,
            name: name,
            lastKnownLat: lastKnownLat,
            lastKnownLon: lastKnownLon,
            lastRefreshed: lastRefreshed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String contactPubkey,
            required String name,
            Value<double?> lastKnownLat = const Value.absent(),
            Value<double?> lastKnownLon = const Value.absent(),
            required int lastRefreshed,
            Value<int> rowid = const Value.absent(),
          }) =>
              KnownContactsCompanion.insert(
            contactPubkey: contactPubkey,
            name: name,
            lastKnownLat: lastKnownLat,
            lastKnownLon: lastKnownLon,
            lastRefreshed: lastRefreshed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KnownContactsTableProcessedTableManager = ProcessedTableManager<
    _$PathGraphDatabase,
    $KnownContactsTable,
    KnownContact,
    $$KnownContactsTableFilterComposer,
    $$KnownContactsTableOrderingComposer,
    $$KnownContactsTableAnnotationComposer,
    $$KnownContactsTableCreateCompanionBuilder,
    $$KnownContactsTableUpdateCompanionBuilder,
    (
      KnownContact,
      BaseReferences<_$PathGraphDatabase, $KnownContactsTable, KnownContact>
    ),
    KnownContact,
    PrefetchHooks Function()>;
typedef $$GraphMetaTableCreateCompanionBuilder = GraphMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$GraphMetaTableUpdateCompanionBuilder = GraphMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$GraphMetaTableFilterComposer
    extends Composer<_$PathGraphDatabase, $GraphMetaTable> {
  $$GraphMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$GraphMetaTableOrderingComposer
    extends Composer<_$PathGraphDatabase, $GraphMetaTable> {
  $$GraphMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$GraphMetaTableAnnotationComposer
    extends Composer<_$PathGraphDatabase, $GraphMetaTable> {
  $$GraphMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$GraphMetaTableTableManager extends RootTableManager<
    _$PathGraphDatabase,
    $GraphMetaTable,
    GraphMetaData,
    $$GraphMetaTableFilterComposer,
    $$GraphMetaTableOrderingComposer,
    $$GraphMetaTableAnnotationComposer,
    $$GraphMetaTableCreateCompanionBuilder,
    $$GraphMetaTableUpdateCompanionBuilder,
    (
      GraphMetaData,
      BaseReferences<_$PathGraphDatabase, $GraphMetaTable, GraphMetaData>
    ),
    GraphMetaData,
    PrefetchHooks Function()> {
  $$GraphMetaTableTableManager(_$PathGraphDatabase db, $GraphMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GraphMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GraphMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GraphMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GraphMetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              GraphMetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GraphMetaTableProcessedTableManager = ProcessedTableManager<
    _$PathGraphDatabase,
    $GraphMetaTable,
    GraphMetaData,
    $$GraphMetaTableFilterComposer,
    $$GraphMetaTableOrderingComposer,
    $$GraphMetaTableAnnotationComposer,
    $$GraphMetaTableCreateCompanionBuilder,
    $$GraphMetaTableUpdateCompanionBuilder,
    (
      GraphMetaData,
      BaseReferences<_$PathGraphDatabase, $GraphMetaTable, GraphMetaData>
    ),
    GraphMetaData,
    PrefetchHooks Function()>;

class $PathGraphDatabaseManager {
  final _$PathGraphDatabase _db;
  $PathGraphDatabaseManager(this._db);
  $$GraphNodesTableTableManager get graphNodes =>
      $$GraphNodesTableTableManager(_db, _db.graphNodes);
  $$GraphEdgesTableTableManager get graphEdges =>
      $$GraphEdgesTableTableManager(_db, _db.graphEdges);
  $$ContactIngressTableTableManager get contactIngress =>
      $$ContactIngressTableTableManager(_db, _db.contactIngress);
  $$KnownContactsTableTableManager get knownContacts =>
      $$KnownContactsTableTableManager(_db, _db.knownContacts);
  $$GraphMetaTableTableManager get graphMeta =>
      $$GraphMetaTableTableManager(_db, _db.graphMeta);
}
