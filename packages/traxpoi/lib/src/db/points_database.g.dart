// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points_database.dart';

// ignore_for_file: type=lint
class Meta extends Table with TableInfo<Meta, MetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Meta(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  MetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaData(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  Meta createAlias(String alias) {
    return Meta(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class MetaData extends DataClass implements Insertable<MetaData> {
  final String name;
  final String value;
  const MetaData({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(name: Value(name), value: Value(value));
  }

  factory MetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaData(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaData copyWith({String? name, String? value}) =>
      MetaData(name: name ?? this.name, value: value ?? this.value);
  MetaData copyWithCompanion(MetaCompanion data) {
    return MetaData(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaData(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaData &&
          other.name == this.name &&
          other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaData> {
  final Value<String> name;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String name,
    required String value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<MetaData> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaCompanion copyWith({
    Value<String>? name,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
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
    return (StringBuffer('MetaCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class NameSearch extends Table
    with
        TableInfo<NameSearch, NameSearchData>,
        VirtualTableInfo<NameSearch, NameSearchData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NameSearch(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _normMeta = const VerificationMeta('norm');
  late final GeneratedColumn<String> norm = GeneratedColumn<String>(
    'norm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [norm];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'name_search';
  @override
  VerificationContext validateIntegrity(
    Insertable<NameSearchData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('norm')) {
      context.handle(
        _normMeta,
        norm.isAcceptableOrUnknown(data['norm']!, _normMeta),
      );
    } else if (isInserting) {
      context.missing(_normMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  NameSearchData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NameSearchData(
      norm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}norm'],
      )!,
    );
  }

  @override
  NameSearch createAlias(String alias) {
    return NameSearch(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(norm, content = \'name\', content_rowid = \'id\', tokenize = \'trigram\')';
}

class NameSearchData extends DataClass implements Insertable<NameSearchData> {
  final String norm;
  const NameSearchData({required this.norm});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['norm'] = Variable<String>(norm);
    return map;
  }

  NameSearchCompanion toCompanion(bool nullToAbsent) {
    return NameSearchCompanion(norm: Value(norm));
  }

  factory NameSearchData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NameSearchData(norm: serializer.fromJson<String>(json['norm']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'norm': serializer.toJson<String>(norm)};
  }

  NameSearchData copyWith({String? norm}) =>
      NameSearchData(norm: norm ?? this.norm);
  NameSearchData copyWithCompanion(NameSearchCompanion data) {
    return NameSearchData(
      norm: data.norm.present ? data.norm.value : this.norm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NameSearchData(')
          ..write('norm: $norm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => norm.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NameSearchData && other.norm == this.norm);
}

class NameSearchCompanion extends UpdateCompanion<NameSearchData> {
  final Value<String> norm;
  final Value<int> rowid;
  const NameSearchCompanion({
    this.norm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NameSearchCompanion.insert({
    required String norm,
    this.rowid = const Value.absent(),
  }) : norm = Value(norm);
  static Insertable<NameSearchData> custom({
    Expression<String>? norm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (norm != null) 'norm': norm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NameSearchCompanion copyWith({Value<String>? norm, Value<int>? rowid}) {
    return NameSearchCompanion(
      norm: norm ?? this.norm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (norm.present) {
      map['norm'] = Variable<String>(norm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NameSearchCompanion(')
          ..write('norm: $norm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Place extends Table with TableInfo<Place, PlaceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Place(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _eleMeta = const VerificationMeta('ele');
  late final GeneratedColumn<int> ele = GeneratedColumn<int>(
    'ele',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _heritageMeta = const VerificationMeta(
    'heritage',
  );
  late final GeneratedColumn<String> heritage = GeneratedColumn<String>(
    'heritage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _wikidataMeta = const VerificationMeta(
    'wikidata',
  );
  late final GeneratedColumn<String> wikidata = GeneratedColumn<String>(
    'wikidata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _osmMeta = const VerificationMeta('osm');
  late final GeneratedColumn<String> osm = GeneratedColumn<String>(
    'osm',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _gnisMeta = const VerificationMeta('gnis');
  late final GeneratedColumn<int> gnis = GeneratedColumn<int>(
    'gnis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _sourcesMeta = const VerificationMeta(
    'sources',
  );
  late final GeneratedColumn<String> sources = GeneratedColumn<String>(
    'sources',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    name,
    detail,
    lat,
    lon,
    ele,
    heritage,
    wikidata,
    osm,
    gnis,
    sources,
    rank,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'place';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaceData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('ele')) {
      context.handle(
        _eleMeta,
        ele.isAcceptableOrUnknown(data['ele']!, _eleMeta),
      );
    }
    if (data.containsKey('heritage')) {
      context.handle(
        _heritageMeta,
        heritage.isAcceptableOrUnknown(data['heritage']!, _heritageMeta),
      );
    }
    if (data.containsKey('wikidata')) {
      context.handle(
        _wikidataMeta,
        wikidata.isAcceptableOrUnknown(data['wikidata']!, _wikidataMeta),
      );
    }
    if (data.containsKey('osm')) {
      context.handle(
        _osmMeta,
        osm.isAcceptableOrUnknown(data['osm']!, _osmMeta),
      );
    }
    if (data.containsKey('gnis')) {
      context.handle(
        _gnisMeta,
        gnis.isAcceptableOrUnknown(data['gnis']!, _gnisMeta),
      );
    }
    if (data.containsKey('sources')) {
      context.handle(
        _sourcesMeta,
        sources.isAcceptableOrUnknown(data['sources']!, _sourcesMeta),
      );
    } else if (isInserting) {
      context.missing(_sourcesMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaceData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      ele: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ele'],
      ),
      heritage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heritage'],
      ),
      wikidata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wikidata'],
      ),
      osm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}osm'],
      ),
      gnis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gnis'],
      ),
      sources: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sources'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
    );
  }

  @override
  Place createAlias(String alias) {
    return Place(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PlaceData extends DataClass implements Insertable<PlaceData> {
  final int id;
  final String kind;
  final String name;
  final String? detail;
  final double lat;
  final double lon;
  final int? ele;
  final String? heritage;
  final String? wikidata;
  final String? osm;
  final int? gnis;
  final String sources;
  final int rank;
  const PlaceData({
    required this.id,
    required this.kind,
    required this.name,
    this.detail,
    required this.lat,
    required this.lon,
    this.ele,
    this.heritage,
    this.wikidata,
    this.osm,
    this.gnis,
    required this.sources,
    required this.rank,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || ele != null) {
      map['ele'] = Variable<int>(ele);
    }
    if (!nullToAbsent || heritage != null) {
      map['heritage'] = Variable<String>(heritage);
    }
    if (!nullToAbsent || wikidata != null) {
      map['wikidata'] = Variable<String>(wikidata);
    }
    if (!nullToAbsent || osm != null) {
      map['osm'] = Variable<String>(osm);
    }
    if (!nullToAbsent || gnis != null) {
      map['gnis'] = Variable<int>(gnis);
    }
    map['sources'] = Variable<String>(sources);
    map['rank'] = Variable<int>(rank);
    return map;
  }

  PlaceCompanion toCompanion(bool nullToAbsent) {
    return PlaceCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      lat: Value(lat),
      lon: Value(lon),
      ele: ele == null && nullToAbsent ? const Value.absent() : Value(ele),
      heritage: heritage == null && nullToAbsent
          ? const Value.absent()
          : Value(heritage),
      wikidata: wikidata == null && nullToAbsent
          ? const Value.absent()
          : Value(wikidata),
      osm: osm == null && nullToAbsent ? const Value.absent() : Value(osm),
      gnis: gnis == null && nullToAbsent ? const Value.absent() : Value(gnis),
      sources: Value(sources),
      rank: Value(rank),
    );
  }

  factory PlaceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaceData(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      detail: serializer.fromJson<String?>(json['detail']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      ele: serializer.fromJson<int?>(json['ele']),
      heritage: serializer.fromJson<String?>(json['heritage']),
      wikidata: serializer.fromJson<String?>(json['wikidata']),
      osm: serializer.fromJson<String?>(json['osm']),
      gnis: serializer.fromJson<int?>(json['gnis']),
      sources: serializer.fromJson<String>(json['sources']),
      rank: serializer.fromJson<int>(json['rank']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'detail': serializer.toJson<String?>(detail),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'ele': serializer.toJson<int?>(ele),
      'heritage': serializer.toJson<String?>(heritage),
      'wikidata': serializer.toJson<String?>(wikidata),
      'osm': serializer.toJson<String?>(osm),
      'gnis': serializer.toJson<int?>(gnis),
      'sources': serializer.toJson<String>(sources),
      'rank': serializer.toJson<int>(rank),
    };
  }

  PlaceData copyWith({
    int? id,
    String? kind,
    String? name,
    Value<String?> detail = const Value.absent(),
    double? lat,
    double? lon,
    Value<int?> ele = const Value.absent(),
    Value<String?> heritage = const Value.absent(),
    Value<String?> wikidata = const Value.absent(),
    Value<String?> osm = const Value.absent(),
    Value<int?> gnis = const Value.absent(),
    String? sources,
    int? rank,
  }) => PlaceData(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    detail: detail.present ? detail.value : this.detail,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    ele: ele.present ? ele.value : this.ele,
    heritage: heritage.present ? heritage.value : this.heritage,
    wikidata: wikidata.present ? wikidata.value : this.wikidata,
    osm: osm.present ? osm.value : this.osm,
    gnis: gnis.present ? gnis.value : this.gnis,
    sources: sources ?? this.sources,
    rank: rank ?? this.rank,
  );
  PlaceData copyWithCompanion(PlaceCompanion data) {
    return PlaceData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      detail: data.detail.present ? data.detail.value : this.detail,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      ele: data.ele.present ? data.ele.value : this.ele,
      heritage: data.heritage.present ? data.heritage.value : this.heritage,
      wikidata: data.wikidata.present ? data.wikidata.value : this.wikidata,
      osm: data.osm.present ? data.osm.value : this.osm,
      gnis: data.gnis.present ? data.gnis.value : this.gnis,
      sources: data.sources.present ? data.sources.value : this.sources,
      rank: data.rank.present ? data.rank.value : this.rank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaceData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('detail: $detail, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('ele: $ele, ')
          ..write('heritage: $heritage, ')
          ..write('wikidata: $wikidata, ')
          ..write('osm: $osm, ')
          ..write('gnis: $gnis, ')
          ..write('sources: $sources, ')
          ..write('rank: $rank')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    detail,
    lat,
    lon,
    ele,
    heritage,
    wikidata,
    osm,
    gnis,
    sources,
    rank,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.detail == this.detail &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.ele == this.ele &&
          other.heritage == this.heritage &&
          other.wikidata == this.wikidata &&
          other.osm == this.osm &&
          other.gnis == this.gnis &&
          other.sources == this.sources &&
          other.rank == this.rank);
}

class PlaceCompanion extends UpdateCompanion<PlaceData> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<String?> detail;
  final Value<double> lat;
  final Value<double> lon;
  final Value<int?> ele;
  final Value<String?> heritage;
  final Value<String?> wikidata;
  final Value<String?> osm;
  final Value<int?> gnis;
  final Value<String> sources;
  final Value<int> rank;
  const PlaceCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.detail = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.ele = const Value.absent(),
    this.heritage = const Value.absent(),
    this.wikidata = const Value.absent(),
    this.osm = const Value.absent(),
    this.gnis = const Value.absent(),
    this.sources = const Value.absent(),
    this.rank = const Value.absent(),
  });
  PlaceCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String name,
    this.detail = const Value.absent(),
    required double lat,
    required double lon,
    this.ele = const Value.absent(),
    this.heritage = const Value.absent(),
    this.wikidata = const Value.absent(),
    this.osm = const Value.absent(),
    this.gnis = const Value.absent(),
    required String sources,
    this.rank = const Value.absent(),
  }) : kind = Value(kind),
       name = Value(name),
       lat = Value(lat),
       lon = Value(lon),
       sources = Value(sources);
  static Insertable<PlaceData> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? detail,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<int>? ele,
    Expression<String>? heritage,
    Expression<String>? wikidata,
    Expression<String>? osm,
    Expression<int>? gnis,
    Expression<String>? sources,
    Expression<int>? rank,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (detail != null) 'detail': detail,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (ele != null) 'ele': ele,
      if (heritage != null) 'heritage': heritage,
      if (wikidata != null) 'wikidata': wikidata,
      if (osm != null) 'osm': osm,
      if (gnis != null) 'gnis': gnis,
      if (sources != null) 'sources': sources,
      if (rank != null) 'rank': rank,
    });
  }

  PlaceCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<String?>? detail,
    Value<double>? lat,
    Value<double>? lon,
    Value<int?>? ele,
    Value<String?>? heritage,
    Value<String?>? wikidata,
    Value<String?>? osm,
    Value<int?>? gnis,
    Value<String>? sources,
    Value<int>? rank,
  }) {
    return PlaceCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      detail: detail ?? this.detail,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      ele: ele ?? this.ele,
      heritage: heritage ?? this.heritage,
      wikidata: wikidata ?? this.wikidata,
      osm: osm ?? this.osm,
      gnis: gnis ?? this.gnis,
      sources: sources ?? this.sources,
      rank: rank ?? this.rank,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (ele.present) {
      map['ele'] = Variable<int>(ele.value);
    }
    if (heritage.present) {
      map['heritage'] = Variable<String>(heritage.value);
    }
    if (wikidata.present) {
      map['wikidata'] = Variable<String>(wikidata.value);
    }
    if (osm.present) {
      map['osm'] = Variable<String>(osm.value);
    }
    if (gnis.present) {
      map['gnis'] = Variable<int>(gnis.value);
    }
    if (sources.present) {
      map['sources'] = Variable<String>(sources.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaceCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('detail: $detail, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('ele: $ele, ')
          ..write('heritage: $heritage, ')
          ..write('wikidata: $wikidata, ')
          ..write('osm: $osm, ')
          ..write('gnis: $gnis, ')
          ..write('sources: $sources, ')
          ..write('rank: $rank')
          ..write(')'))
        .toString();
  }
}

class Feature extends Table with TableInfo<Feature, FeatureData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Feature(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _shapeMeta = const VerificationMeta('shape');
  late final GeneratedColumn<String> shape = GeneratedColumn<String>(
    'shape',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, name, lat, lon, shape];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feature';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeatureData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('shape')) {
      context.handle(
        _shapeMeta,
        shape.isAcceptableOrUnknown(data['shape']!, _shapeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeatureData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeatureData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      shape: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shape'],
      ),
    );
  }

  @override
  Feature createAlias(String alias) {
    return Feature(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class FeatureData extends DataClass implements Insertable<FeatureData> {
  final int id;
  final String kind;
  final String name;
  final double lat;
  final double lon;
  final String? shape;
  const FeatureData({
    required this.id,
    required this.kind,
    required this.name,
    required this.lat,
    required this.lon,
    this.shape,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || shape != null) {
      map['shape'] = Variable<String>(shape);
    }
    return map;
  }

  FeatureCompanion toCompanion(bool nullToAbsent) {
    return FeatureCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      lat: Value(lat),
      lon: Value(lon),
      shape: shape == null && nullToAbsent
          ? const Value.absent()
          : Value(shape),
    );
  }

  factory FeatureData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeatureData(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      shape: serializer.fromJson<String?>(json['shape']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'shape': serializer.toJson<String?>(shape),
    };
  }

  FeatureData copyWith({
    int? id,
    String? kind,
    String? name,
    double? lat,
    double? lon,
    Value<String?> shape = const Value.absent(),
  }) => FeatureData(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    shape: shape.present ? shape.value : this.shape,
  );
  FeatureData copyWithCompanion(FeatureCompanion data) {
    return FeatureData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      shape: data.shape.present ? data.shape.value : this.shape,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeatureData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('shape: $shape')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, name, lat, lon, shape);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeatureData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.shape == this.shape);
}

class FeatureCompanion extends UpdateCompanion<FeatureData> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String?> shape;
  const FeatureCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.shape = const Value.absent(),
  });
  FeatureCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String name,
    required double lat,
    required double lon,
    this.shape = const Value.absent(),
  }) : kind = Value(kind),
       name = Value(name),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<FeatureData> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? shape,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (shape != null) 'shape': shape,
    });
  }

  FeatureCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<double>? lat,
    Value<double>? lon,
    Value<String?>? shape,
  }) {
    return FeatureCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      shape: shape ?? this.shape,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (shape.present) {
      map['shape'] = Variable<String>(shape.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeatureCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('shape: $shape')
          ..write(')'))
        .toString();
  }
}

class Name extends Table with TableInfo<Name, NameData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Name(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _placeIdMeta = const VerificationMeta(
    'placeId',
  );
  late final GeneratedColumn<int> placeId = GeneratedColumn<int>(
    'place_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES place(id)',
  );
  static const VerificationMeta _featureIdMeta = const VerificationMeta(
    'featureId',
  );
  late final GeneratedColumn<int> featureId = GeneratedColumn<int>(
    'feature_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES feature(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _normMeta = const VerificationMeta('norm');
  late final GeneratedColumn<String> norm = GeneratedColumn<String>(
    'norm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    placeId,
    featureId,
    name,
    norm,
    role,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'name';
  @override
  VerificationContext validateIntegrity(
    Insertable<NameData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('place_id')) {
      context.handle(
        _placeIdMeta,
        placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta),
      );
    }
    if (data.containsKey('feature_id')) {
      context.handle(
        _featureIdMeta,
        featureId.isAcceptableOrUnknown(data['feature_id']!, _featureIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('norm')) {
      context.handle(
        _normMeta,
        norm.isAcceptableOrUnknown(data['norm']!, _normMeta),
      );
    } else if (isInserting) {
      context.missing(_normMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NameData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NameData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      placeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}place_id'],
      ),
      featureId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feature_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      norm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}norm'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
    );
  }

  @override
  Name createAlias(String alias) {
    return Name(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((place_id IS NULL)<>(feature_id IS NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class NameData extends DataClass implements Insertable<NameData> {
  final int id;
  final int? placeId;
  final int? featureId;
  final String name;
  final String norm;
  final String role;
  const NameData({
    required this.id,
    this.placeId,
    this.featureId,
    required this.name,
    required this.norm,
    required this.role,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || placeId != null) {
      map['place_id'] = Variable<int>(placeId);
    }
    if (!nullToAbsent || featureId != null) {
      map['feature_id'] = Variable<int>(featureId);
    }
    map['name'] = Variable<String>(name);
    map['norm'] = Variable<String>(norm);
    map['role'] = Variable<String>(role);
    return map;
  }

  NameCompanion toCompanion(bool nullToAbsent) {
    return NameCompanion(
      id: Value(id),
      placeId: placeId == null && nullToAbsent
          ? const Value.absent()
          : Value(placeId),
      featureId: featureId == null && nullToAbsent
          ? const Value.absent()
          : Value(featureId),
      name: Value(name),
      norm: Value(norm),
      role: Value(role),
    );
  }

  factory NameData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NameData(
      id: serializer.fromJson<int>(json['id']),
      placeId: serializer.fromJson<int?>(json['place_id']),
      featureId: serializer.fromJson<int?>(json['feature_id']),
      name: serializer.fromJson<String>(json['name']),
      norm: serializer.fromJson<String>(json['norm']),
      role: serializer.fromJson<String>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'place_id': serializer.toJson<int?>(placeId),
      'feature_id': serializer.toJson<int?>(featureId),
      'name': serializer.toJson<String>(name),
      'norm': serializer.toJson<String>(norm),
      'role': serializer.toJson<String>(role),
    };
  }

  NameData copyWith({
    int? id,
    Value<int?> placeId = const Value.absent(),
    Value<int?> featureId = const Value.absent(),
    String? name,
    String? norm,
    String? role,
  }) => NameData(
    id: id ?? this.id,
    placeId: placeId.present ? placeId.value : this.placeId,
    featureId: featureId.present ? featureId.value : this.featureId,
    name: name ?? this.name,
    norm: norm ?? this.norm,
    role: role ?? this.role,
  );
  NameData copyWithCompanion(NameCompanion data) {
    return NameData(
      id: data.id.present ? data.id.value : this.id,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      featureId: data.featureId.present ? data.featureId.value : this.featureId,
      name: data.name.present ? data.name.value : this.name,
      norm: data.norm.present ? data.norm.value : this.norm,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NameData(')
          ..write('id: $id, ')
          ..write('placeId: $placeId, ')
          ..write('featureId: $featureId, ')
          ..write('name: $name, ')
          ..write('norm: $norm, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, placeId, featureId, name, norm, role);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NameData &&
          other.id == this.id &&
          other.placeId == this.placeId &&
          other.featureId == this.featureId &&
          other.name == this.name &&
          other.norm == this.norm &&
          other.role == this.role);
}

class NameCompanion extends UpdateCompanion<NameData> {
  final Value<int> id;
  final Value<int?> placeId;
  final Value<int?> featureId;
  final Value<String> name;
  final Value<String> norm;
  final Value<String> role;
  const NameCompanion({
    this.id = const Value.absent(),
    this.placeId = const Value.absent(),
    this.featureId = const Value.absent(),
    this.name = const Value.absent(),
    this.norm = const Value.absent(),
    this.role = const Value.absent(),
  });
  NameCompanion.insert({
    this.id = const Value.absent(),
    this.placeId = const Value.absent(),
    this.featureId = const Value.absent(),
    required String name,
    required String norm,
    required String role,
  }) : name = Value(name),
       norm = Value(norm),
       role = Value(role);
  static Insertable<NameData> custom({
    Expression<int>? id,
    Expression<int>? placeId,
    Expression<int>? featureId,
    Expression<String>? name,
    Expression<String>? norm,
    Expression<String>? role,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (placeId != null) 'place_id': placeId,
      if (featureId != null) 'feature_id': featureId,
      if (name != null) 'name': name,
      if (norm != null) 'norm': norm,
      if (role != null) 'role': role,
    });
  }

  NameCompanion copyWith({
    Value<int>? id,
    Value<int?>? placeId,
    Value<int?>? featureId,
    Value<String>? name,
    Value<String>? norm,
    Value<String>? role,
  }) {
    return NameCompanion(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      featureId: featureId ?? this.featureId,
      name: name ?? this.name,
      norm: norm ?? this.norm,
      role: role ?? this.role,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<int>(placeId.value);
    }
    if (featureId.present) {
      map['feature_id'] = Variable<int>(featureId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (norm.present) {
      map['norm'] = Variable<String>(norm.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NameCompanion(')
          ..write('id: $id, ')
          ..write('placeId: $placeId, ')
          ..write('featureId: $featureId, ')
          ..write('name: $name, ')
          ..write('norm: $norm, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }
}

class PlaceArea extends Table
    with
        TableInfo<PlaceArea, PlaceAreaData>,
        VirtualTableInfo<PlaceArea, PlaceAreaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PlaceArea(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _minLatMeta = const VerificationMeta('minLat');
  late final GeneratedColumn<double> minLat = GeneratedColumn<double>(
    'min_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _maxLatMeta = const VerificationMeta('maxLat');
  late final GeneratedColumn<double> maxLat = GeneratedColumn<double>(
    'max_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _minLonMeta = const VerificationMeta('minLon');
  late final GeneratedColumn<double> minLon = GeneratedColumn<double>(
    'min_lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _maxLonMeta = const VerificationMeta('maxLon');
  late final GeneratedColumn<double> maxLon = GeneratedColumn<double>(
    'max_lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, minLat, maxLat, minLon, maxLon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'place_area';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaceAreaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('min_lat')) {
      context.handle(
        _minLatMeta,
        minLat.isAcceptableOrUnknown(data['min_lat']!, _minLatMeta),
      );
    } else if (isInserting) {
      context.missing(_minLatMeta);
    }
    if (data.containsKey('max_lat')) {
      context.handle(
        _maxLatMeta,
        maxLat.isAcceptableOrUnknown(data['max_lat']!, _maxLatMeta),
      );
    } else if (isInserting) {
      context.missing(_maxLatMeta);
    }
    if (data.containsKey('min_lon')) {
      context.handle(
        _minLonMeta,
        minLon.isAcceptableOrUnknown(data['min_lon']!, _minLonMeta),
      );
    } else if (isInserting) {
      context.missing(_minLonMeta);
    }
    if (data.containsKey('max_lon')) {
      context.handle(
        _maxLonMeta,
        maxLon.isAcceptableOrUnknown(data['max_lon']!, _maxLonMeta),
      );
    } else if (isInserting) {
      context.missing(_maxLonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  PlaceAreaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaceAreaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      minLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_lat'],
      )!,
      maxLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_lat'],
      )!,
      minLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_lon'],
      )!,
      maxLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_lon'],
      )!,
    );
  }

  @override
  PlaceArea createAlias(String alias) {
    return PlaceArea(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs => 'rtree(id, min_lat, max_lat, min_lon, max_lon)';
}

class PlaceAreaData extends DataClass implements Insertable<PlaceAreaData> {
  final int id;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  const PlaceAreaData({
    required this.id,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['min_lat'] = Variable<double>(minLat);
    map['max_lat'] = Variable<double>(maxLat);
    map['min_lon'] = Variable<double>(minLon);
    map['max_lon'] = Variable<double>(maxLon);
    return map;
  }

  PlaceAreaCompanion toCompanion(bool nullToAbsent) {
    return PlaceAreaCompanion(
      id: Value(id),
      minLat: Value(minLat),
      maxLat: Value(maxLat),
      minLon: Value(minLon),
      maxLon: Value(maxLon),
    );
  }

  factory PlaceAreaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaceAreaData(
      id: serializer.fromJson<int>(json['id']),
      minLat: serializer.fromJson<double>(json['min_lat']),
      maxLat: serializer.fromJson<double>(json['max_lat']),
      minLon: serializer.fromJson<double>(json['min_lon']),
      maxLon: serializer.fromJson<double>(json['max_lon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'min_lat': serializer.toJson<double>(minLat),
      'max_lat': serializer.toJson<double>(maxLat),
      'min_lon': serializer.toJson<double>(minLon),
      'max_lon': serializer.toJson<double>(maxLon),
    };
  }

  PlaceAreaData copyWith({
    int? id,
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
  }) => PlaceAreaData(
    id: id ?? this.id,
    minLat: minLat ?? this.minLat,
    maxLat: maxLat ?? this.maxLat,
    minLon: minLon ?? this.minLon,
    maxLon: maxLon ?? this.maxLon,
  );
  PlaceAreaData copyWithCompanion(PlaceAreaCompanion data) {
    return PlaceAreaData(
      id: data.id.present ? data.id.value : this.id,
      minLat: data.minLat.present ? data.minLat.value : this.minLat,
      maxLat: data.maxLat.present ? data.maxLat.value : this.maxLat,
      minLon: data.minLon.present ? data.minLon.value : this.minLon,
      maxLon: data.maxLon.present ? data.maxLon.value : this.maxLon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaceAreaData(')
          ..write('id: $id, ')
          ..write('minLat: $minLat, ')
          ..write('maxLat: $maxLat, ')
          ..write('minLon: $minLon, ')
          ..write('maxLon: $maxLon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, minLat, maxLat, minLon, maxLon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceAreaData &&
          other.id == this.id &&
          other.minLat == this.minLat &&
          other.maxLat == this.maxLat &&
          other.minLon == this.minLon &&
          other.maxLon == this.maxLon);
}

class PlaceAreaCompanion extends UpdateCompanion<PlaceAreaData> {
  final Value<int> id;
  final Value<double> minLat;
  final Value<double> maxLat;
  final Value<double> minLon;
  final Value<double> maxLon;
  final Value<int> rowid;
  const PlaceAreaCompanion({
    this.id = const Value.absent(),
    this.minLat = const Value.absent(),
    this.maxLat = const Value.absent(),
    this.minLon = const Value.absent(),
    this.maxLon = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaceAreaCompanion.insert({
    required int id,
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       minLat = Value(minLat),
       maxLat = Value(maxLat),
       minLon = Value(minLon),
       maxLon = Value(maxLon);
  static Insertable<PlaceAreaData> custom({
    Expression<int>? id,
    Expression<double>? minLat,
    Expression<double>? maxLat,
    Expression<double>? minLon,
    Expression<double>? maxLon,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (minLat != null) 'min_lat': minLat,
      if (maxLat != null) 'max_lat': maxLat,
      if (minLon != null) 'min_lon': minLon,
      if (maxLon != null) 'max_lon': maxLon,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaceAreaCompanion copyWith({
    Value<int>? id,
    Value<double>? minLat,
    Value<double>? maxLat,
    Value<double>? minLon,
    Value<double>? maxLon,
    Value<int>? rowid,
  }) {
    return PlaceAreaCompanion(
      id: id ?? this.id,
      minLat: minLat ?? this.minLat,
      maxLat: maxLat ?? this.maxLat,
      minLon: minLon ?? this.minLon,
      maxLon: maxLon ?? this.maxLon,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (minLat.present) {
      map['min_lat'] = Variable<double>(minLat.value);
    }
    if (maxLat.present) {
      map['max_lat'] = Variable<double>(maxLat.value);
    }
    if (minLon.present) {
      map['min_lon'] = Variable<double>(minLon.value);
    }
    if (maxLon.present) {
      map['max_lon'] = Variable<double>(maxLon.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaceAreaCompanion(')
          ..write('id: $id, ')
          ..write('minLat: $minLat, ')
          ..write('maxLat: $maxLat, ')
          ..write('minLon: $minLon, ')
          ..write('maxLon: $maxLon, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Wiki extends Table with TableInfo<Wiki, WikiData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Wiki(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _placeIdMeta = const VerificationMeta(
    'placeId',
  );
  late final GeneratedColumn<int> placeId = GeneratedColumn<int>(
    'place_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES place(id)',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [placeId, title, summary];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wiki';
  @override
  VerificationContext validateIntegrity(
    Insertable<WikiData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('place_id')) {
      context.handle(
        _placeIdMeta,
        placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {placeId};
  @override
  WikiData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WikiData(
      placeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}place_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
    );
  }

  @override
  Wiki createAlias(String alias) {
    return Wiki(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WikiData extends DataClass implements Insertable<WikiData> {
  final int placeId;
  final String title;
  final String summary;
  const WikiData({
    required this.placeId,
    required this.title,
    required this.summary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['place_id'] = Variable<int>(placeId);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    return map;
  }

  WikiCompanion toCompanion(bool nullToAbsent) {
    return WikiCompanion(
      placeId: Value(placeId),
      title: Value(title),
      summary: Value(summary),
    );
  }

  factory WikiData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WikiData(
      placeId: serializer.fromJson<int>(json['place_id']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'place_id': serializer.toJson<int>(placeId),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
    };
  }

  WikiData copyWith({int? placeId, String? title, String? summary}) => WikiData(
    placeId: placeId ?? this.placeId,
    title: title ?? this.title,
    summary: summary ?? this.summary,
  );
  WikiData copyWithCompanion(WikiCompanion data) {
    return WikiData(
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WikiData(')
          ..write('placeId: $placeId, ')
          ..write('title: $title, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(placeId, title, summary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WikiData &&
          other.placeId == this.placeId &&
          other.title == this.title &&
          other.summary == this.summary);
}

class WikiCompanion extends UpdateCompanion<WikiData> {
  final Value<int> placeId;
  final Value<String> title;
  final Value<String> summary;
  const WikiCompanion({
    this.placeId = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
  });
  WikiCompanion.insert({
    this.placeId = const Value.absent(),
    required String title,
    required String summary,
  }) : title = Value(title),
       summary = Value(summary);
  static Insertable<WikiData> custom({
    Expression<int>? placeId,
    Expression<String>? title,
    Expression<String>? summary,
  }) {
    return RawValuesInsertable({
      if (placeId != null) 'place_id': placeId,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
    });
  }

  WikiCompanion copyWith({
    Value<int>? placeId,
    Value<String>? title,
    Value<String>? summary,
  }) {
    return WikiCompanion(
      placeId: placeId ?? this.placeId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (placeId.present) {
      map['place_id'] = Variable<int>(placeId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WikiCompanion(')
          ..write('placeId: $placeId, ')
          ..write('title: $title, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }
}

class Photo extends Table with TableInfo<Photo, PhotoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Photo(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _placeIdMeta = const VerificationMeta(
    'placeId',
  );
  late final GeneratedColumn<int> placeId = GeneratedColumn<int>(
    'place_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES place(id)',
  );
  static const VerificationMeta _webpMeta = const VerificationMeta('webp');
  late final GeneratedColumn<Uint8List> webp = GeneratedColumn<Uint8List>(
    'webp',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fileMeta = const VerificationMeta('file');
  late final GeneratedColumn<String> file = GeneratedColumn<String>(
    'file',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _licenceMeta = const VerificationMeta(
    'licence',
  );
  late final GeneratedColumn<String> licence = GeneratedColumn<String>(
    'licence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _licenceUrlMeta = const VerificationMeta(
    'licenceUrl',
  );
  late final GeneratedColumn<String> licenceUrl = GeneratedColumn<String>(
    'licence_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    placeId,
    webp,
    width,
    height,
    file,
    author,
    licence,
    licenceUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('place_id')) {
      context.handle(
        _placeIdMeta,
        placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta),
      );
    }
    if (data.containsKey('webp')) {
      context.handle(
        _webpMeta,
        webp.isAcceptableOrUnknown(data['webp']!, _webpMeta),
      );
    } else if (isInserting) {
      context.missing(_webpMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('file')) {
      context.handle(
        _fileMeta,
        file.isAcceptableOrUnknown(data['file']!, _fileMeta),
      );
    } else if (isInserting) {
      context.missing(_fileMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('licence')) {
      context.handle(
        _licenceMeta,
        licence.isAcceptableOrUnknown(data['licence']!, _licenceMeta),
      );
    } else if (isInserting) {
      context.missing(_licenceMeta);
    }
    if (data.containsKey('licence_url')) {
      context.handle(
        _licenceUrlMeta,
        licenceUrl.isAcceptableOrUnknown(data['licence_url']!, _licenceUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {placeId};
  @override
  PhotoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoData(
      placeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}place_id'],
      )!,
      webp: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}webp'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      file: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      licence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}licence'],
      )!,
      licenceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}licence_url'],
      ),
    );
  }

  @override
  Photo createAlias(String alias) {
    return Photo(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PhotoData extends DataClass implements Insertable<PhotoData> {
  final int placeId;
  final Uint8List webp;
  final int width;
  final int height;
  final String file;
  final String author;
  final String licence;
  final String? licenceUrl;
  const PhotoData({
    required this.placeId,
    required this.webp,
    required this.width,
    required this.height,
    required this.file,
    required this.author,
    required this.licence,
    this.licenceUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['place_id'] = Variable<int>(placeId);
    map['webp'] = Variable<Uint8List>(webp);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['file'] = Variable<String>(file);
    map['author'] = Variable<String>(author);
    map['licence'] = Variable<String>(licence);
    if (!nullToAbsent || licenceUrl != null) {
      map['licence_url'] = Variable<String>(licenceUrl);
    }
    return map;
  }

  PhotoCompanion toCompanion(bool nullToAbsent) {
    return PhotoCompanion(
      placeId: Value(placeId),
      webp: Value(webp),
      width: Value(width),
      height: Value(height),
      file: Value(file),
      author: Value(author),
      licence: Value(licence),
      licenceUrl: licenceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(licenceUrl),
    );
  }

  factory PhotoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoData(
      placeId: serializer.fromJson<int>(json['place_id']),
      webp: serializer.fromJson<Uint8List>(json['webp']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      file: serializer.fromJson<String>(json['file']),
      author: serializer.fromJson<String>(json['author']),
      licence: serializer.fromJson<String>(json['licence']),
      licenceUrl: serializer.fromJson<String?>(json['licence_url']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'place_id': serializer.toJson<int>(placeId),
      'webp': serializer.toJson<Uint8List>(webp),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'file': serializer.toJson<String>(file),
      'author': serializer.toJson<String>(author),
      'licence': serializer.toJson<String>(licence),
      'licence_url': serializer.toJson<String?>(licenceUrl),
    };
  }

  PhotoData copyWith({
    int? placeId,
    Uint8List? webp,
    int? width,
    int? height,
    String? file,
    String? author,
    String? licence,
    Value<String?> licenceUrl = const Value.absent(),
  }) => PhotoData(
    placeId: placeId ?? this.placeId,
    webp: webp ?? this.webp,
    width: width ?? this.width,
    height: height ?? this.height,
    file: file ?? this.file,
    author: author ?? this.author,
    licence: licence ?? this.licence,
    licenceUrl: licenceUrl.present ? licenceUrl.value : this.licenceUrl,
  );
  PhotoData copyWithCompanion(PhotoCompanion data) {
    return PhotoData(
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      webp: data.webp.present ? data.webp.value : this.webp,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      file: data.file.present ? data.file.value : this.file,
      author: data.author.present ? data.author.value : this.author,
      licence: data.licence.present ? data.licence.value : this.licence,
      licenceUrl: data.licenceUrl.present
          ? data.licenceUrl.value
          : this.licenceUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoData(')
          ..write('placeId: $placeId, ')
          ..write('webp: $webp, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('file: $file, ')
          ..write('author: $author, ')
          ..write('licence: $licence, ')
          ..write('licenceUrl: $licenceUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    placeId,
    $driftBlobEquality.hash(webp),
    width,
    height,
    file,
    author,
    licence,
    licenceUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoData &&
          other.placeId == this.placeId &&
          $driftBlobEquality.equals(other.webp, this.webp) &&
          other.width == this.width &&
          other.height == this.height &&
          other.file == this.file &&
          other.author == this.author &&
          other.licence == this.licence &&
          other.licenceUrl == this.licenceUrl);
}

class PhotoCompanion extends UpdateCompanion<PhotoData> {
  final Value<int> placeId;
  final Value<Uint8List> webp;
  final Value<int> width;
  final Value<int> height;
  final Value<String> file;
  final Value<String> author;
  final Value<String> licence;
  final Value<String?> licenceUrl;
  const PhotoCompanion({
    this.placeId = const Value.absent(),
    this.webp = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.file = const Value.absent(),
    this.author = const Value.absent(),
    this.licence = const Value.absent(),
    this.licenceUrl = const Value.absent(),
  });
  PhotoCompanion.insert({
    this.placeId = const Value.absent(),
    required Uint8List webp,
    required int width,
    required int height,
    required String file,
    required String author,
    required String licence,
    this.licenceUrl = const Value.absent(),
  }) : webp = Value(webp),
       width = Value(width),
       height = Value(height),
       file = Value(file),
       author = Value(author),
       licence = Value(licence);
  static Insertable<PhotoData> custom({
    Expression<int>? placeId,
    Expression<Uint8List>? webp,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? file,
    Expression<String>? author,
    Expression<String>? licence,
    Expression<String>? licenceUrl,
  }) {
    return RawValuesInsertable({
      if (placeId != null) 'place_id': placeId,
      if (webp != null) 'webp': webp,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (file != null) 'file': file,
      if (author != null) 'author': author,
      if (licence != null) 'licence': licence,
      if (licenceUrl != null) 'licence_url': licenceUrl,
    });
  }

  PhotoCompanion copyWith({
    Value<int>? placeId,
    Value<Uint8List>? webp,
    Value<int>? width,
    Value<int>? height,
    Value<String>? file,
    Value<String>? author,
    Value<String>? licence,
    Value<String?>? licenceUrl,
  }) {
    return PhotoCompanion(
      placeId: placeId ?? this.placeId,
      webp: webp ?? this.webp,
      width: width ?? this.width,
      height: height ?? this.height,
      file: file ?? this.file,
      author: author ?? this.author,
      licence: licence ?? this.licence,
      licenceUrl: licenceUrl ?? this.licenceUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (placeId.present) {
      map['place_id'] = Variable<int>(placeId.value);
    }
    if (webp.present) {
      map['webp'] = Variable<Uint8List>(webp.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (file.present) {
      map['file'] = Variable<String>(file.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (licence.present) {
      map['licence'] = Variable<String>(licence.value);
    }
    if (licenceUrl.present) {
      map['licence_url'] = Variable<String>(licenceUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoCompanion(')
          ..write('placeId: $placeId, ')
          ..write('webp: $webp, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('file: $file, ')
          ..write('author: $author, ')
          ..write('licence: $licence, ')
          ..write('licenceUrl: $licenceUrl')
          ..write(')'))
        .toString();
  }
}

abstract class _$PointsDatabase extends GeneratedDatabase {
  _$PointsDatabase(QueryExecutor e) : super(e);
  late final Meta meta = Meta(this);
  late final NameSearch nameSearch = NameSearch(this);
  late final Place place = Place(this);
  late final Feature feature = Feature(this);
  late final Name name = Name(this);
  late final PlaceArea placeArea = PlaceArea(this);
  late final Wiki wiki = Wiki(this);
  late final Photo photo = Photo(this);
  Selectable<String> metaValue(String name) {
    return customSelect(
      'SELECT value FROM meta WHERE name = ?1',
      variables: [Variable<String>(name)],
      readsFrom: {this.meta},
    ).map((QueryRow row) => row.read<String>('value'));
  }

  Selectable<NameCandidatesResult> nameCandidates(String query, int limit) {
    return customSelect(
      'SELECT n.id, n.place_id, n.feature_id, n.name, n.norm FROM name_search AS s INNER JOIN name AS n ON n.id = s."rowid" WHERE name_search MATCH ?1 ORDER BY s.rank LIMIT ?2',
      variables: [Variable<String>(query), Variable<int>(limit)],
      readsFrom: {this.name, this.nameSearch},
    ).map(
      (QueryRow row) => NameCandidatesResult(
        id: row.read<int>('id'),
        placeId: row.readNullable<int>('place_id'),
        featureId: row.readNullable<int>('feature_id'),
        name: row.read<String>('name'),
        norm: row.read<String>('norm'),
      ),
    );
  }

  Selectable<NamePrefixResult> namePrefix(String prefix, int limit) {
    return customSelect(
      'SELECT id, place_id, feature_id, name, norm FROM name WHERE norm LIKE ?1 LIMIT ?2',
      variables: [Variable<String>(prefix), Variable<int>(limit)],
      readsFrom: {this.name},
    ).map(
      (QueryRow row) => NamePrefixResult(
        id: row.read<int>('id'),
        placeId: row.readNullable<int>('place_id'),
        featureId: row.readNullable<int>('feature_id'),
        name: row.read<String>('name'),
        norm: row.read<String>('norm'),
      ),
    );
  }

  Selectable<PlacesInResult> placesIn(
    double north,
    double south,
    double east,
    double west,
    int limit,
  ) {
    return customSelect(
      'SELECT"p"."id" AS "nested_0.id", "p"."kind" AS "nested_0.kind", "p"."name" AS "nested_0.name", "p"."detail" AS "nested_0.detail", "p"."lat" AS "nested_0.lat", "p"."lon" AS "nested_0.lon", "p"."ele" AS "nested_0.ele", "p"."heritage" AS "nested_0.heritage", "p"."wikidata" AS "nested_0.wikidata", "p"."osm" AS "nested_0.osm", "p"."gnis" AS "nested_0.gnis", "p"."sources" AS "nested_0.sources", "p"."rank" AS "nested_0.rank" FROM place_area AS a INNER JOIN place AS p ON p.id = a.id WHERE a.min_lat <= ?1 AND a.max_lat >= ?2 AND a.min_lon <= ?3 AND a.max_lon >= ?4 ORDER BY p.rank DESC LIMIT ?5',
      variables: [
        Variable<double>(north),
        Variable<double>(south),
        Variable<double>(east),
        Variable<double>(west),
        Variable<int>(limit),
      ],
      readsFrom: {this.placeArea, this.place},
    ).asyncMap(
      (QueryRow row) async => PlacesInResult(
        p: await this.place.mapFromRow(row, tablePrefix: 'nested_0'),
      ),
    );
  }

  Selectable<PlaceData> placeById(int id) {
    return customSelect(
      'SELECT * FROM place WHERE id = ?1',
      variables: [Variable<int>(id)],
      readsFrom: {this.place},
    ).asyncMap(this.place.mapFromRow);
  }

  Selectable<FeatureData> featureById(int id) {
    return customSelect(
      'SELECT * FROM feature WHERE id = ?1',
      variables: [Variable<int>(id)],
      readsFrom: {this.feature},
    ).asyncMap(this.feature.mapFromRow);
  }

  Selectable<WikiData> wikiFor(int id) {
    return customSelect(
      'SELECT * FROM wiki WHERE place_id = ?1',
      variables: [Variable<int>(id)],
      readsFrom: {this.wiki},
    ).asyncMap(this.wiki.mapFromRow);
  }

  Selectable<PhotoData> photoFor(int id) {
    return customSelect(
      'SELECT * FROM photo WHERE place_id = ?1',
      variables: [Variable<int>(id)],
      readsFrom: {this.photo},
    ).asyncMap(this.photo.mapFromRow);
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    meta,
    nameSearch,
    place,
    feature,
    name,
    placeArea,
    wiki,
    photo,
  ];
}

class NameCandidatesResult {
  final int id;
  final int? placeId;
  final int? featureId;
  final String name;
  final String norm;
  NameCandidatesResult({
    required this.id,
    this.placeId,
    this.featureId,
    required this.name,
    required this.norm,
  });
}

class NamePrefixResult {
  final int id;
  final int? placeId;
  final int? featureId;
  final String name;
  final String norm;
  NamePrefixResult({
    required this.id,
    this.placeId,
    this.featureId,
    required this.name,
    required this.norm,
  });
}

class PlacesInResult {
  final PlaceData p;
  PlacesInResult({required this.p});
}
