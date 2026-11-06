// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addresses_database.dart';

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

class StreetSearch extends Table
    with
        TableInfo<StreetSearch, StreetSearchData>,
        VirtualTableInfo<StreetSearch, StreetSearchData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StreetSearch(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'street_search';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreetSearchData> instance, {
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
  StreetSearchData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreetSearchData(
      norm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}norm'],
      )!,
    );
  }

  @override
  StreetSearch createAlias(String alias) {
    return StreetSearch(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(norm, content = \'street\', content_rowid = \'id\', tokenize = \'trigram\')';
}

class StreetSearchData extends DataClass
    implements Insertable<StreetSearchData> {
  final String norm;
  const StreetSearchData({required this.norm});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['norm'] = Variable<String>(norm);
    return map;
  }

  StreetSearchCompanion toCompanion(bool nullToAbsent) {
    return StreetSearchCompanion(norm: Value(norm));
  }

  factory StreetSearchData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreetSearchData(norm: serializer.fromJson<String>(json['norm']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'norm': serializer.toJson<String>(norm)};
  }

  StreetSearchData copyWith({String? norm}) =>
      StreetSearchData(norm: norm ?? this.norm);
  StreetSearchData copyWithCompanion(StreetSearchCompanion data) {
    return StreetSearchData(
      norm: data.norm.present ? data.norm.value : this.norm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreetSearchData(')
          ..write('norm: $norm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => norm.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreetSearchData && other.norm == this.norm);
}

class StreetSearchCompanion extends UpdateCompanion<StreetSearchData> {
  final Value<String> norm;
  final Value<int> rowid;
  const StreetSearchCompanion({
    this.norm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreetSearchCompanion.insert({
    required String norm,
    this.rowid = const Value.absent(),
  }) : norm = Value(norm);
  static Insertable<StreetSearchData> custom({
    Expression<String>? norm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (norm != null) 'norm': norm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreetSearchCompanion copyWith({Value<String>? norm, Value<int>? rowid}) {
    return StreetSearchCompanion(
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
    return (StringBuffer('StreetSearchCompanion(')
          ..write('norm: $norm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Street extends Table with TableInfo<Street, StreetData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Street(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
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
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _zipMeta = const VerificationMeta('zip');
  late final GeneratedColumn<String> zip = GeneratedColumn<String>(
    'zip',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, norm, city, zip];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'street';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreetData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('zip')) {
      context.handle(
        _zipMeta,
        zip.isAcceptableOrUnknown(data['zip']!, _zipMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreetData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreetData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      norm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}norm'],
      )!,
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      zip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zip'],
      ),
    );
  }

  @override
  Street createAlias(String alias) {
    return Street(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class StreetData extends DataClass implements Insertable<StreetData> {
  final int id;
  final String name;
  final String norm;
  final String? city;
  final String? zip;
  const StreetData({
    required this.id,
    required this.name,
    required this.norm,
    this.city,
    this.zip,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['norm'] = Variable<String>(norm);
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || zip != null) {
      map['zip'] = Variable<String>(zip);
    }
    return map;
  }

  StreetCompanion toCompanion(bool nullToAbsent) {
    return StreetCompanion(
      id: Value(id),
      name: Value(name),
      norm: Value(norm),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      zip: zip == null && nullToAbsent ? const Value.absent() : Value(zip),
    );
  }

  factory StreetData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreetData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      norm: serializer.fromJson<String>(json['norm']),
      city: serializer.fromJson<String?>(json['city']),
      zip: serializer.fromJson<String?>(json['zip']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'norm': serializer.toJson<String>(norm),
      'city': serializer.toJson<String?>(city),
      'zip': serializer.toJson<String?>(zip),
    };
  }

  StreetData copyWith({
    int? id,
    String? name,
    String? norm,
    Value<String?> city = const Value.absent(),
    Value<String?> zip = const Value.absent(),
  }) => StreetData(
    id: id ?? this.id,
    name: name ?? this.name,
    norm: norm ?? this.norm,
    city: city.present ? city.value : this.city,
    zip: zip.present ? zip.value : this.zip,
  );
  StreetData copyWithCompanion(StreetCompanion data) {
    return StreetData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      norm: data.norm.present ? data.norm.value : this.norm,
      city: data.city.present ? data.city.value : this.city,
      zip: data.zip.present ? data.zip.value : this.zip,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreetData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('norm: $norm, ')
          ..write('city: $city, ')
          ..write('zip: $zip')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, norm, city, zip);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreetData &&
          other.id == this.id &&
          other.name == this.name &&
          other.norm == this.norm &&
          other.city == this.city &&
          other.zip == this.zip);
}

class StreetCompanion extends UpdateCompanion<StreetData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> norm;
  final Value<String?> city;
  final Value<String?> zip;
  const StreetCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.norm = const Value.absent(),
    this.city = const Value.absent(),
    this.zip = const Value.absent(),
  });
  StreetCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String norm,
    this.city = const Value.absent(),
    this.zip = const Value.absent(),
  }) : name = Value(name),
       norm = Value(norm);
  static Insertable<StreetData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? norm,
    Expression<String>? city,
    Expression<String>? zip,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (norm != null) 'norm': norm,
      if (city != null) 'city': city,
      if (zip != null) 'zip': zip,
    });
  }

  StreetCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? norm,
    Value<String?>? city,
    Value<String?>? zip,
  }) {
    return StreetCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      norm: norm ?? this.norm,
      city: city ?? this.city,
      zip: zip ?? this.zip,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (norm.present) {
      map['norm'] = Variable<String>(norm.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (zip.present) {
      map['zip'] = Variable<String>(zip.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreetCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('norm: $norm, ')
          ..write('city: $city, ')
          ..write('zip: $zip')
          ..write(')'))
        .toString();
  }
}

class Address extends Table with TableInfo<Address, AddressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Address(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _streetIdMeta = const VerificationMeta(
    'streetId',
  );
  late final GeneratedColumn<int> streetId = GeneratedColumn<int>(
    'street_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES street(id)',
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
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
  @override
  List<GeneratedColumn> get $columns => [id, streetId, number, unit, lat, lon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'address';
  @override
  VerificationContext validateIntegrity(
    Insertable<AddressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('street_id')) {
      context.handle(
        _streetIdMeta,
        streetId.isAcceptableOrUnknown(data['street_id']!, _streetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streetIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AddressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AddressData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      streetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}street_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
    );
  }

  @override
  Address createAlias(String alias) {
    return Address(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AddressData extends DataClass implements Insertable<AddressData> {
  final int id;
  final int streetId;
  final String number;
  final String? unit;
  final double lat;
  final double lon;
  const AddressData({
    required this.id,
    required this.streetId,
    required this.number,
    this.unit,
    required this.lat,
    required this.lon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['street_id'] = Variable<int>(streetId);
    map['number'] = Variable<String>(number);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    return map;
  }

  AddressCompanion toCompanion(bool nullToAbsent) {
    return AddressCompanion(
      id: Value(id),
      streetId: Value(streetId),
      number: Value(number),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      lat: Value(lat),
      lon: Value(lon),
    );
  }

  factory AddressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AddressData(
      id: serializer.fromJson<int>(json['id']),
      streetId: serializer.fromJson<int>(json['street_id']),
      number: serializer.fromJson<String>(json['number']),
      unit: serializer.fromJson<String?>(json['unit']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'street_id': serializer.toJson<int>(streetId),
      'number': serializer.toJson<String>(number),
      'unit': serializer.toJson<String?>(unit),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
    };
  }

  AddressData copyWith({
    int? id,
    int? streetId,
    String? number,
    Value<String?> unit = const Value.absent(),
    double? lat,
    double? lon,
  }) => AddressData(
    id: id ?? this.id,
    streetId: streetId ?? this.streetId,
    number: number ?? this.number,
    unit: unit.present ? unit.value : this.unit,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
  );
  AddressData copyWithCompanion(AddressCompanion data) {
    return AddressData(
      id: data.id.present ? data.id.value : this.id,
      streetId: data.streetId.present ? data.streetId.value : this.streetId,
      number: data.number.present ? data.number.value : this.number,
      unit: data.unit.present ? data.unit.value : this.unit,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AddressData(')
          ..write('id: $id, ')
          ..write('streetId: $streetId, ')
          ..write('number: $number, ')
          ..write('unit: $unit, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, streetId, number, unit, lat, lon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AddressData &&
          other.id == this.id &&
          other.streetId == this.streetId &&
          other.number == this.number &&
          other.unit == this.unit &&
          other.lat == this.lat &&
          other.lon == this.lon);
}

class AddressCompanion extends UpdateCompanion<AddressData> {
  final Value<int> id;
  final Value<int> streetId;
  final Value<String> number;
  final Value<String?> unit;
  final Value<double> lat;
  final Value<double> lon;
  const AddressCompanion({
    this.id = const Value.absent(),
    this.streetId = const Value.absent(),
    this.number = const Value.absent(),
    this.unit = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
  });
  AddressCompanion.insert({
    this.id = const Value.absent(),
    required int streetId,
    required String number,
    this.unit = const Value.absent(),
    required double lat,
    required double lon,
  }) : streetId = Value(streetId),
       number = Value(number),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<AddressData> custom({
    Expression<int>? id,
    Expression<int>? streetId,
    Expression<String>? number,
    Expression<String>? unit,
    Expression<double>? lat,
    Expression<double>? lon,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (streetId != null) 'street_id': streetId,
      if (number != null) 'number': number,
      if (unit != null) 'unit': unit,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
    });
  }

  AddressCompanion copyWith({
    Value<int>? id,
    Value<int>? streetId,
    Value<String>? number,
    Value<String?>? unit,
    Value<double>? lat,
    Value<double>? lon,
  }) {
    return AddressCompanion(
      id: id ?? this.id,
      streetId: streetId ?? this.streetId,
      number: number ?? this.number,
      unit: unit ?? this.unit,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (streetId.present) {
      map['street_id'] = Variable<int>(streetId.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AddressCompanion(')
          ..write('id: $id, ')
          ..write('streetId: $streetId, ')
          ..write('number: $number, ')
          ..write('unit: $unit, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon')
          ..write(')'))
        .toString();
  }
}

abstract class _$AddressesDatabase extends GeneratedDatabase {
  _$AddressesDatabase(QueryExecutor e) : super(e);
  late final Meta meta = Meta(this);
  late final StreetSearch streetSearch = StreetSearch(this);
  late final Street street = Street(this);
  late final Address address = Address(this);
  late final Index addressStreet = Index(
    'address_street',
    'CREATE INDEX address_street ON address (street_id, number)',
  );
  Selectable<String> metaValue(String name) {
    return customSelect(
      'SELECT value FROM meta WHERE name = ?1',
      variables: [Variable<String>(name)],
      readsFrom: {this.meta},
    ).map((QueryRow row) => row.read<String>('value'));
  }

  Selectable<StreetData> streetCandidates(String query, int limit) {
    return customSelect(
      'SELECT st.id, st.name, st.norm, st.city, st.zip FROM street_search AS s INNER JOIN street AS st ON st.id = s."rowid" WHERE street_search MATCH ?1 ORDER BY s.rank LIMIT ?2',
      variables: [Variable<String>(query), Variable<int>(limit)],
      readsFrom: {this.street, this.streetSearch},
    ).asyncMap(this.street.mapFromRow);
  }

  Selectable<AddressData> addressesOn(int streetId, String number) {
    return customSelect(
      'SELECT * FROM address WHERE street_id = ?1 AND number = ?2 COLLATE NOCASE',
      variables: [Variable<int>(streetId), Variable<String>(number)],
      readsFrom: {this.address},
    ).asyncMap(this.address.mapFromRow);
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    meta,
    streetSearch,
    street,
    address,
    addressStreet,
  ];
}
