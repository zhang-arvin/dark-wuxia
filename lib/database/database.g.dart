// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EquipmentTableTable extends EquipmentTable
    with TableInfo<$EquipmentTableTable, EquipmentTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EquipmentTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseIdMeta = const VerificationMeta('baseId');
  @override
  late final GeneratedColumn<String> baseId = GeneratedColumn<String>(
      'base_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qualityMeta =
      const VerificationMeta('quality');
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
      'quality', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
      'slot', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _affixesJsonMeta =
      const VerificationMeta('affixesJson');
  @override
  late final GeneratedColumn<String> affixesJson = GeneratedColumn<String>(
      'affixes_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _reinforceLevelMeta =
      const VerificationMeta('reinforceLevel');
  @override
  late final GeneratedColumn<int> reinforceLevel = GeneratedColumn<int>(
      'reinforce_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _meridianSeedIdMeta =
      const VerificationMeta('meridianSeedId');
  @override
  late final GeneratedColumn<String> meridianSeedId = GeneratedColumn<String>(
      'meridian_seed_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _itemLevelMeta =
      const VerificationMeta('itemLevel');
  @override
  late final GeneratedColumn<int> itemLevel = GeneratedColumn<int>(
      'item_level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isEquippedMeta =
      const VerificationMeta('isEquipped');
  @override
  late final GeneratedColumn<bool> isEquipped = GeneratedColumn<bool>(
      'is_equipped', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_equipped" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        baseId,
        quality,
        slot,
        name,
        affixesJson,
        reinforceLevel,
        meridianSeedId,
        itemLevel,
        isEquipped,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'equipment_table';
  @override
  VerificationContext validateIntegrity(Insertable<EquipmentTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('base_id')) {
      context.handle(_baseIdMeta,
          baseId.isAcceptableOrUnknown(data['base_id']!, _baseIdMeta));
    } else if (isInserting) {
      context.missing(_baseIdMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(_qualityMeta,
          quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta));
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('affixes_json')) {
      context.handle(
          _affixesJsonMeta,
          affixesJson.isAcceptableOrUnknown(
              data['affixes_json']!, _affixesJsonMeta));
    }
    if (data.containsKey('reinforce_level')) {
      context.handle(
          _reinforceLevelMeta,
          reinforceLevel.isAcceptableOrUnknown(
              data['reinforce_level']!, _reinforceLevelMeta));
    }
    if (data.containsKey('meridian_seed_id')) {
      context.handle(
          _meridianSeedIdMeta,
          meridianSeedId.isAcceptableOrUnknown(
              data['meridian_seed_id']!, _meridianSeedIdMeta));
    }
    if (data.containsKey('item_level')) {
      context.handle(_itemLevelMeta,
          itemLevel.isAcceptableOrUnknown(data['item_level']!, _itemLevelMeta));
    } else if (isInserting) {
      context.missing(_itemLevelMeta);
    }
    if (data.containsKey('is_equipped')) {
      context.handle(
          _isEquippedMeta,
          isEquipped.isAcceptableOrUnknown(
              data['is_equipped']!, _isEquippedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EquipmentTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EquipmentTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      baseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_id'])!,
      quality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quality'])!,
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      affixesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}affixes_json'])!,
      reinforceLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reinforce_level'])!,
      meridianSeedId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}meridian_seed_id']),
      itemLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_level'])!,
      isEquipped: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_equipped'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EquipmentTableTable createAlias(String alias) {
    return $EquipmentTableTable(attachedDatabase, alias);
  }
}

class EquipmentTableData extends DataClass
    implements Insertable<EquipmentTableData> {
  /// 装备唯一 ID (UUID)
  final String id;

  /// 基础装备 ID (指向 JSON 配置)
  final String baseId;

  /// 品质: normal / magic / rare / unique / divine / legendary
  final String quality;

  /// 装备槽位: weapon / armor / accessory / treasure
  final String slot;

  /// 生成名 (含词缀前缀后缀)
  final String name;

  /// 词缀列表 JSON 字符串
  /// 格式: [{"id":"sharp","type":"prefix","name":"锋利的","stat":"outerDamage","value":15,"isPercent":true}, ...]
  final String affixesJson;

  /// 强化等级 (0-15)
  final int reinforceLevel;

  /// 镶嵌的真气种子 ID (可空)
  final String? meridianSeedId;

  /// 物品等级 (影响词缀范围)
  final int itemLevel;

  /// 是否已装备 (false=在背包中, true=已装备在槽位上)
  final bool isEquipped;

  /// 创建时间戳
  final DateTime createdAt;
  const EquipmentTableData(
      {required this.id,
      required this.baseId,
      required this.quality,
      required this.slot,
      required this.name,
      required this.affixesJson,
      required this.reinforceLevel,
      this.meridianSeedId,
      required this.itemLevel,
      required this.isEquipped,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['base_id'] = Variable<String>(baseId);
    map['quality'] = Variable<String>(quality);
    map['slot'] = Variable<String>(slot);
    map['name'] = Variable<String>(name);
    map['affixes_json'] = Variable<String>(affixesJson);
    map['reinforce_level'] = Variable<int>(reinforceLevel);
    if (!nullToAbsent || meridianSeedId != null) {
      map['meridian_seed_id'] = Variable<String>(meridianSeedId);
    }
    map['item_level'] = Variable<int>(itemLevel);
    map['is_equipped'] = Variable<bool>(isEquipped);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EquipmentTableCompanion toCompanion(bool nullToAbsent) {
    return EquipmentTableCompanion(
      id: Value(id),
      baseId: Value(baseId),
      quality: Value(quality),
      slot: Value(slot),
      name: Value(name),
      affixesJson: Value(affixesJson),
      reinforceLevel: Value(reinforceLevel),
      meridianSeedId: meridianSeedId == null && nullToAbsent
          ? const Value.absent()
          : Value(meridianSeedId),
      itemLevel: Value(itemLevel),
      isEquipped: Value(isEquipped),
      createdAt: Value(createdAt),
    );
  }

  factory EquipmentTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EquipmentTableData(
      id: serializer.fromJson<String>(json['id']),
      baseId: serializer.fromJson<String>(json['baseId']),
      quality: serializer.fromJson<String>(json['quality']),
      slot: serializer.fromJson<String>(json['slot']),
      name: serializer.fromJson<String>(json['name']),
      affixesJson: serializer.fromJson<String>(json['affixesJson']),
      reinforceLevel: serializer.fromJson<int>(json['reinforceLevel']),
      meridianSeedId: serializer.fromJson<String?>(json['meridianSeedId']),
      itemLevel: serializer.fromJson<int>(json['itemLevel']),
      isEquipped: serializer.fromJson<bool>(json['isEquipped']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'baseId': serializer.toJson<String>(baseId),
      'quality': serializer.toJson<String>(quality),
      'slot': serializer.toJson<String>(slot),
      'name': serializer.toJson<String>(name),
      'affixesJson': serializer.toJson<String>(affixesJson),
      'reinforceLevel': serializer.toJson<int>(reinforceLevel),
      'meridianSeedId': serializer.toJson<String?>(meridianSeedId),
      'itemLevel': serializer.toJson<int>(itemLevel),
      'isEquipped': serializer.toJson<bool>(isEquipped),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EquipmentTableData copyWith(
          {String? id,
          String? baseId,
          String? quality,
          String? slot,
          String? name,
          String? affixesJson,
          int? reinforceLevel,
          Value<String?> meridianSeedId = const Value.absent(),
          int? itemLevel,
          bool? isEquipped,
          DateTime? createdAt}) =>
      EquipmentTableData(
        id: id ?? this.id,
        baseId: baseId ?? this.baseId,
        quality: quality ?? this.quality,
        slot: slot ?? this.slot,
        name: name ?? this.name,
        affixesJson: affixesJson ?? this.affixesJson,
        reinforceLevel: reinforceLevel ?? this.reinforceLevel,
        meridianSeedId:
            meridianSeedId.present ? meridianSeedId.value : this.meridianSeedId,
        itemLevel: itemLevel ?? this.itemLevel,
        isEquipped: isEquipped ?? this.isEquipped,
        createdAt: createdAt ?? this.createdAt,
      );
  EquipmentTableData copyWithCompanion(EquipmentTableCompanion data) {
    return EquipmentTableData(
      id: data.id.present ? data.id.value : this.id,
      baseId: data.baseId.present ? data.baseId.value : this.baseId,
      quality: data.quality.present ? data.quality.value : this.quality,
      slot: data.slot.present ? data.slot.value : this.slot,
      name: data.name.present ? data.name.value : this.name,
      affixesJson:
          data.affixesJson.present ? data.affixesJson.value : this.affixesJson,
      reinforceLevel: data.reinforceLevel.present
          ? data.reinforceLevel.value
          : this.reinforceLevel,
      meridianSeedId: data.meridianSeedId.present
          ? data.meridianSeedId.value
          : this.meridianSeedId,
      itemLevel: data.itemLevel.present ? data.itemLevel.value : this.itemLevel,
      isEquipped:
          data.isEquipped.present ? data.isEquipped.value : this.isEquipped,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EquipmentTableData(')
          ..write('id: $id, ')
          ..write('baseId: $baseId, ')
          ..write('quality: $quality, ')
          ..write('slot: $slot, ')
          ..write('name: $name, ')
          ..write('affixesJson: $affixesJson, ')
          ..write('reinforceLevel: $reinforceLevel, ')
          ..write('meridianSeedId: $meridianSeedId, ')
          ..write('itemLevel: $itemLevel, ')
          ..write('isEquipped: $isEquipped, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, baseId, quality, slot, name, affixesJson,
      reinforceLevel, meridianSeedId, itemLevel, isEquipped, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EquipmentTableData &&
          other.id == this.id &&
          other.baseId == this.baseId &&
          other.quality == this.quality &&
          other.slot == this.slot &&
          other.name == this.name &&
          other.affixesJson == this.affixesJson &&
          other.reinforceLevel == this.reinforceLevel &&
          other.meridianSeedId == this.meridianSeedId &&
          other.itemLevel == this.itemLevel &&
          other.isEquipped == this.isEquipped &&
          other.createdAt == this.createdAt);
}

class EquipmentTableCompanion extends UpdateCompanion<EquipmentTableData> {
  final Value<String> id;
  final Value<String> baseId;
  final Value<String> quality;
  final Value<String> slot;
  final Value<String> name;
  final Value<String> affixesJson;
  final Value<int> reinforceLevel;
  final Value<String?> meridianSeedId;
  final Value<int> itemLevel;
  final Value<bool> isEquipped;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EquipmentTableCompanion({
    this.id = const Value.absent(),
    this.baseId = const Value.absent(),
    this.quality = const Value.absent(),
    this.slot = const Value.absent(),
    this.name = const Value.absent(),
    this.affixesJson = const Value.absent(),
    this.reinforceLevel = const Value.absent(),
    this.meridianSeedId = const Value.absent(),
    this.itemLevel = const Value.absent(),
    this.isEquipped = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EquipmentTableCompanion.insert({
    required String id,
    required String baseId,
    required String quality,
    required String slot,
    required String name,
    this.affixesJson = const Value.absent(),
    this.reinforceLevel = const Value.absent(),
    this.meridianSeedId = const Value.absent(),
    required int itemLevel,
    this.isEquipped = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        baseId = Value(baseId),
        quality = Value(quality),
        slot = Value(slot),
        name = Value(name),
        itemLevel = Value(itemLevel);
  static Insertable<EquipmentTableData> custom({
    Expression<String>? id,
    Expression<String>? baseId,
    Expression<String>? quality,
    Expression<String>? slot,
    Expression<String>? name,
    Expression<String>? affixesJson,
    Expression<int>? reinforceLevel,
    Expression<String>? meridianSeedId,
    Expression<int>? itemLevel,
    Expression<bool>? isEquipped,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseId != null) 'base_id': baseId,
      if (quality != null) 'quality': quality,
      if (slot != null) 'slot': slot,
      if (name != null) 'name': name,
      if (affixesJson != null) 'affixes_json': affixesJson,
      if (reinforceLevel != null) 'reinforce_level': reinforceLevel,
      if (meridianSeedId != null) 'meridian_seed_id': meridianSeedId,
      if (itemLevel != null) 'item_level': itemLevel,
      if (isEquipped != null) 'is_equipped': isEquipped,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EquipmentTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? baseId,
      Value<String>? quality,
      Value<String>? slot,
      Value<String>? name,
      Value<String>? affixesJson,
      Value<int>? reinforceLevel,
      Value<String?>? meridianSeedId,
      Value<int>? itemLevel,
      Value<bool>? isEquipped,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return EquipmentTableCompanion(
      id: id ?? this.id,
      baseId: baseId ?? this.baseId,
      quality: quality ?? this.quality,
      slot: slot ?? this.slot,
      name: name ?? this.name,
      affixesJson: affixesJson ?? this.affixesJson,
      reinforceLevel: reinforceLevel ?? this.reinforceLevel,
      meridianSeedId: meridianSeedId ?? this.meridianSeedId,
      itemLevel: itemLevel ?? this.itemLevel,
      isEquipped: isEquipped ?? this.isEquipped,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (baseId.present) {
      map['base_id'] = Variable<String>(baseId.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (affixesJson.present) {
      map['affixes_json'] = Variable<String>(affixesJson.value);
    }
    if (reinforceLevel.present) {
      map['reinforce_level'] = Variable<int>(reinforceLevel.value);
    }
    if (meridianSeedId.present) {
      map['meridian_seed_id'] = Variable<String>(meridianSeedId.value);
    }
    if (itemLevel.present) {
      map['item_level'] = Variable<int>(itemLevel.value);
    }
    if (isEquipped.present) {
      map['is_equipped'] = Variable<bool>(isEquipped.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EquipmentTableCompanion(')
          ..write('id: $id, ')
          ..write('baseId: $baseId, ')
          ..write('quality: $quality, ')
          ..write('slot: $slot, ')
          ..write('name: $name, ')
          ..write('affixesJson: $affixesJson, ')
          ..write('reinforceLevel: $reinforceLevel, ')
          ..write('meridianSeedId: $meridianSeedId, ')
          ..write('itemLevel: $itemLevel, ')
          ..write('isEquipped: $isEquipped, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterTableTable extends CharacterTable
    with TableInfo<$CharacterTableTable, CharacterTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
      'origin', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _attributesJsonMeta =
      const VerificationMeta('attributesJson');
  @override
  late final GeneratedColumn<String> attributesJson = GeneratedColumn<String>(
      'attributes_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
      'age', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(16));
  static const VerificationMeta _healthMeta = const VerificationMeta('health');
  @override
  late final GeneratedColumn<int> health = GeneratedColumn<int>(
      'health', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _innerEnergyMeta =
      const VerificationMeta('innerEnergy');
  @override
  late final GeneratedColumn<int> innerEnergy = GeneratedColumn<int>(
      'inner_energy', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(50));
  static const VerificationMeta _fortuneMeta =
      const VerificationMeta('fortune');
  @override
  late final GeneratedColumn<int> fortune = GeneratedColumn<int>(
      'fortune', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reputationMeta =
      const VerificationMeta('reputation');
  @override
  late final GeneratedColumn<int> reputation = GeneratedColumn<int>(
      'reputation', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _alignmentMeta =
      const VerificationMeta('alignment');
  @override
  late final GeneratedColumn<int> alignment = GeneratedColumn<int>(
      'alignment', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _powerIndexMeta =
      const VerificationMeta('powerIndex');
  @override
  late final GeneratedColumn<int> powerIndex = GeneratedColumn<int>(
      'power_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _martialArtsJsonMeta =
      const VerificationMeta('martialArtsJson');
  @override
  late final GeneratedColumn<String> martialArtsJson = GeneratedColumn<String>(
      'martial_arts_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _meridiansJsonMeta =
      const VerificationMeta('meridiansJson');
  @override
  late final GeneratedColumn<String> meridiansJson = GeneratedColumn<String>(
      'meridians_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _heartMantraMeta =
      const VerificationMeta('heartMantra');
  @override
  late final GeneratedColumn<String> heartMantra = GeneratedColumn<String>(
      'heart_mantra', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _silverMeta = const VerificationMeta('silver');
  @override
  late final GeneratedColumn<int> silver = GeneratedColumn<int>(
      'silver', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        origin,
        level,
        attributesJson,
        age,
        health,
        innerEnergy,
        fortune,
        reputation,
        alignment,
        powerIndex,
        martialArtsJson,
        meridiansJson,
        heartMantra,
        silver,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_table';
  @override
  VerificationContext validateIntegrity(Insertable<CharacterTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(_originMeta,
          origin.isAcceptableOrUnknown(data['origin']!, _originMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('attributes_json')) {
      context.handle(
          _attributesJsonMeta,
          attributesJson.isAcceptableOrUnknown(
              data['attributes_json']!, _attributesJsonMeta));
    }
    if (data.containsKey('age')) {
      context.handle(
          _ageMeta, age.isAcceptableOrUnknown(data['age']!, _ageMeta));
    }
    if (data.containsKey('health')) {
      context.handle(_healthMeta,
          health.isAcceptableOrUnknown(data['health']!, _healthMeta));
    }
    if (data.containsKey('inner_energy')) {
      context.handle(
          _innerEnergyMeta,
          innerEnergy.isAcceptableOrUnknown(
              data['inner_energy']!, _innerEnergyMeta));
    }
    if (data.containsKey('fortune')) {
      context.handle(_fortuneMeta,
          fortune.isAcceptableOrUnknown(data['fortune']!, _fortuneMeta));
    }
    if (data.containsKey('reputation')) {
      context.handle(
          _reputationMeta,
          reputation.isAcceptableOrUnknown(
              data['reputation']!, _reputationMeta));
    }
    if (data.containsKey('alignment')) {
      context.handle(_alignmentMeta,
          alignment.isAcceptableOrUnknown(data['alignment']!, _alignmentMeta));
    }
    if (data.containsKey('power_index')) {
      context.handle(
          _powerIndexMeta,
          powerIndex.isAcceptableOrUnknown(
              data['power_index']!, _powerIndexMeta));
    }
    if (data.containsKey('martial_arts_json')) {
      context.handle(
          _martialArtsJsonMeta,
          martialArtsJson.isAcceptableOrUnknown(
              data['martial_arts_json']!, _martialArtsJsonMeta));
    }
    if (data.containsKey('meridians_json')) {
      context.handle(
          _meridiansJsonMeta,
          meridiansJson.isAcceptableOrUnknown(
              data['meridians_json']!, _meridiansJsonMeta));
    }
    if (data.containsKey('heart_mantra')) {
      context.handle(
          _heartMantraMeta,
          heartMantra.isAcceptableOrUnknown(
              data['heart_mantra']!, _heartMantraMeta));
    }
    if (data.containsKey('silver')) {
      context.handle(_silverMeta,
          silver.isAcceptableOrUnknown(data['silver']!, _silverMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      origin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
      attributesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}attributes_json'])!,
      age: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age'])!,
      health: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}health'])!,
      innerEnergy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}inner_energy'])!,
      fortune: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fortune'])!,
      reputation: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reputation'])!,
      alignment: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}alignment'])!,
      powerIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}power_index'])!,
      martialArtsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}martial_arts_json'])!,
      meridiansJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meridians_json'])!,
      heartMantra: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}heart_mantra']),
      silver: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}silver'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CharacterTableTable createAlias(String alias) {
    return $CharacterTableTable(attachedDatabase, alias);
  }
}

class CharacterTableData extends DataClass
    implements Insertable<CharacterTableData> {
  /// 主键固定为 1 (单角色)
  final int id;

  /// 角色名
  final String name;

  /// 出身
  final String origin;

  /// 等级
  final int level;

  /// 五维属性 JSON: {"body":10,"agi":8,"wis":12,"con":10,"luck":5}
  final String attributesJson;

  /// 年龄
  final int age;

  /// 当前生命值
  final int health;

  /// 当前内力值
  final int innerEnergy;

  /// 福缘 (掉率加成, =D2的MF)
  final int fortune;

  /// 名望
  final int reputation;

  /// 正邪值 -100~100
  final int alignment;

  /// 战力指数 (综合评分)
  final int powerIndex;

  /// 武功列表 JSON
  /// 格式: [{"id":"shaolin_quan","name":"少林长拳","type":"outer","proficiency":30,"level":"beginner","elementAffinity":"yang"}, ...]
  final String martialArtsJson;

  /// 经脉状态 JSON (6脉30穴)
  /// 格式: [{"meridianId":"yang1","nodeIndex":0,"isOpen":true,"seedId":"seed_fire"}, ...]
  final String meridiansJson;

  /// 心法 ID (可空)
  final String? heartMantra;

  /// 银两 (货币，用于购买/赌博/强化)
  final int silver;

  /// 最后更新时间
  final DateTime updatedAt;
  const CharacterTableData(
      {required this.id,
      required this.name,
      required this.origin,
      required this.level,
      required this.attributesJson,
      required this.age,
      required this.health,
      required this.innerEnergy,
      required this.fortune,
      required this.reputation,
      required this.alignment,
      required this.powerIndex,
      required this.martialArtsJson,
      required this.meridiansJson,
      this.heartMantra,
      required this.silver,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['origin'] = Variable<String>(origin);
    map['level'] = Variable<int>(level);
    map['attributes_json'] = Variable<String>(attributesJson);
    map['age'] = Variable<int>(age);
    map['health'] = Variable<int>(health);
    map['inner_energy'] = Variable<int>(innerEnergy);
    map['fortune'] = Variable<int>(fortune);
    map['reputation'] = Variable<int>(reputation);
    map['alignment'] = Variable<int>(alignment);
    map['power_index'] = Variable<int>(powerIndex);
    map['martial_arts_json'] = Variable<String>(martialArtsJson);
    map['meridians_json'] = Variable<String>(meridiansJson);
    if (!nullToAbsent || heartMantra != null) {
      map['heart_mantra'] = Variable<String>(heartMantra);
    }
    map['silver'] = Variable<int>(silver);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CharacterTableCompanion toCompanion(bool nullToAbsent) {
    return CharacterTableCompanion(
      id: Value(id),
      name: Value(name),
      origin: Value(origin),
      level: Value(level),
      attributesJson: Value(attributesJson),
      age: Value(age),
      health: Value(health),
      innerEnergy: Value(innerEnergy),
      fortune: Value(fortune),
      reputation: Value(reputation),
      alignment: Value(alignment),
      powerIndex: Value(powerIndex),
      martialArtsJson: Value(martialArtsJson),
      meridiansJson: Value(meridiansJson),
      heartMantra: heartMantra == null && nullToAbsent
          ? const Value.absent()
          : Value(heartMantra),
      silver: Value(silver),
      updatedAt: Value(updatedAt),
    );
  }

  factory CharacterTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      origin: serializer.fromJson<String>(json['origin']),
      level: serializer.fromJson<int>(json['level']),
      attributesJson: serializer.fromJson<String>(json['attributesJson']),
      age: serializer.fromJson<int>(json['age']),
      health: serializer.fromJson<int>(json['health']),
      innerEnergy: serializer.fromJson<int>(json['innerEnergy']),
      fortune: serializer.fromJson<int>(json['fortune']),
      reputation: serializer.fromJson<int>(json['reputation']),
      alignment: serializer.fromJson<int>(json['alignment']),
      powerIndex: serializer.fromJson<int>(json['powerIndex']),
      martialArtsJson: serializer.fromJson<String>(json['martialArtsJson']),
      meridiansJson: serializer.fromJson<String>(json['meridiansJson']),
      heartMantra: serializer.fromJson<String?>(json['heartMantra']),
      silver: serializer.fromJson<int>(json['silver']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'origin': serializer.toJson<String>(origin),
      'level': serializer.toJson<int>(level),
      'attributesJson': serializer.toJson<String>(attributesJson),
      'age': serializer.toJson<int>(age),
      'health': serializer.toJson<int>(health),
      'innerEnergy': serializer.toJson<int>(innerEnergy),
      'fortune': serializer.toJson<int>(fortune),
      'reputation': serializer.toJson<int>(reputation),
      'alignment': serializer.toJson<int>(alignment),
      'powerIndex': serializer.toJson<int>(powerIndex),
      'martialArtsJson': serializer.toJson<String>(martialArtsJson),
      'meridiansJson': serializer.toJson<String>(meridiansJson),
      'heartMantra': serializer.toJson<String?>(heartMantra),
      'silver': serializer.toJson<int>(silver),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CharacterTableData copyWith(
          {int? id,
          String? name,
          String? origin,
          int? level,
          String? attributesJson,
          int? age,
          int? health,
          int? innerEnergy,
          int? fortune,
          int? reputation,
          int? alignment,
          int? powerIndex,
          String? martialArtsJson,
          String? meridiansJson,
          Value<String?> heartMantra = const Value.absent(),
          int? silver,
          DateTime? updatedAt}) =>
      CharacterTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        origin: origin ?? this.origin,
        level: level ?? this.level,
        attributesJson: attributesJson ?? this.attributesJson,
        age: age ?? this.age,
        health: health ?? this.health,
        innerEnergy: innerEnergy ?? this.innerEnergy,
        fortune: fortune ?? this.fortune,
        reputation: reputation ?? this.reputation,
        alignment: alignment ?? this.alignment,
        powerIndex: powerIndex ?? this.powerIndex,
        martialArtsJson: martialArtsJson ?? this.martialArtsJson,
        meridiansJson: meridiansJson ?? this.meridiansJson,
        heartMantra: heartMantra.present ? heartMantra.value : this.heartMantra,
        silver: silver ?? this.silver,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CharacterTableData copyWithCompanion(CharacterTableCompanion data) {
    return CharacterTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      origin: data.origin.present ? data.origin.value : this.origin,
      level: data.level.present ? data.level.value : this.level,
      attributesJson: data.attributesJson.present
          ? data.attributesJson.value
          : this.attributesJson,
      age: data.age.present ? data.age.value : this.age,
      health: data.health.present ? data.health.value : this.health,
      innerEnergy:
          data.innerEnergy.present ? data.innerEnergy.value : this.innerEnergy,
      fortune: data.fortune.present ? data.fortune.value : this.fortune,
      reputation:
          data.reputation.present ? data.reputation.value : this.reputation,
      alignment: data.alignment.present ? data.alignment.value : this.alignment,
      powerIndex:
          data.powerIndex.present ? data.powerIndex.value : this.powerIndex,
      martialArtsJson: data.martialArtsJson.present
          ? data.martialArtsJson.value
          : this.martialArtsJson,
      meridiansJson: data.meridiansJson.present
          ? data.meridiansJson.value
          : this.meridiansJson,
      heartMantra:
          data.heartMantra.present ? data.heartMantra.value : this.heartMantra,
      silver: data.silver.present ? data.silver.value : this.silver,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('origin: $origin, ')
          ..write('level: $level, ')
          ..write('attributesJson: $attributesJson, ')
          ..write('age: $age, ')
          ..write('health: $health, ')
          ..write('innerEnergy: $innerEnergy, ')
          ..write('fortune: $fortune, ')
          ..write('reputation: $reputation, ')
          ..write('alignment: $alignment, ')
          ..write('powerIndex: $powerIndex, ')
          ..write('martialArtsJson: $martialArtsJson, ')
          ..write('meridiansJson: $meridiansJson, ')
          ..write('heartMantra: $heartMantra, ')
          ..write('silver: $silver, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      origin,
      level,
      attributesJson,
      age,
      health,
      innerEnergy,
      fortune,
      reputation,
      alignment,
      powerIndex,
      martialArtsJson,
      meridiansJson,
      heartMantra,
      silver,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.origin == this.origin &&
          other.level == this.level &&
          other.attributesJson == this.attributesJson &&
          other.age == this.age &&
          other.health == this.health &&
          other.innerEnergy == this.innerEnergy &&
          other.fortune == this.fortune &&
          other.reputation == this.reputation &&
          other.alignment == this.alignment &&
          other.powerIndex == this.powerIndex &&
          other.martialArtsJson == this.martialArtsJson &&
          other.meridiansJson == this.meridiansJson &&
          other.heartMantra == this.heartMantra &&
          other.silver == this.silver &&
          other.updatedAt == this.updatedAt);
}

class CharacterTableCompanion extends UpdateCompanion<CharacterTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> origin;
  final Value<int> level;
  final Value<String> attributesJson;
  final Value<int> age;
  final Value<int> health;
  final Value<int> innerEnergy;
  final Value<int> fortune;
  final Value<int> reputation;
  final Value<int> alignment;
  final Value<int> powerIndex;
  final Value<String> martialArtsJson;
  final Value<String> meridiansJson;
  final Value<String?> heartMantra;
  final Value<int> silver;
  final Value<DateTime> updatedAt;
  const CharacterTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.origin = const Value.absent(),
    this.level = const Value.absent(),
    this.attributesJson = const Value.absent(),
    this.age = const Value.absent(),
    this.health = const Value.absent(),
    this.innerEnergy = const Value.absent(),
    this.fortune = const Value.absent(),
    this.reputation = const Value.absent(),
    this.alignment = const Value.absent(),
    this.powerIndex = const Value.absent(),
    this.martialArtsJson = const Value.absent(),
    this.meridiansJson = const Value.absent(),
    this.heartMantra = const Value.absent(),
    this.silver = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CharacterTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.origin = const Value.absent(),
    this.level = const Value.absent(),
    this.attributesJson = const Value.absent(),
    this.age = const Value.absent(),
    this.health = const Value.absent(),
    this.innerEnergy = const Value.absent(),
    this.fortune = const Value.absent(),
    this.reputation = const Value.absent(),
    this.alignment = const Value.absent(),
    this.powerIndex = const Value.absent(),
    this.martialArtsJson = const Value.absent(),
    this.meridiansJson = const Value.absent(),
    this.heartMantra = const Value.absent(),
    this.silver = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CharacterTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? origin,
    Expression<int>? level,
    Expression<String>? attributesJson,
    Expression<int>? age,
    Expression<int>? health,
    Expression<int>? innerEnergy,
    Expression<int>? fortune,
    Expression<int>? reputation,
    Expression<int>? alignment,
    Expression<int>? powerIndex,
    Expression<String>? martialArtsJson,
    Expression<String>? meridiansJson,
    Expression<String>? heartMantra,
    Expression<int>? silver,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (origin != null) 'origin': origin,
      if (level != null) 'level': level,
      if (attributesJson != null) 'attributes_json': attributesJson,
      if (age != null) 'age': age,
      if (health != null) 'health': health,
      if (innerEnergy != null) 'inner_energy': innerEnergy,
      if (fortune != null) 'fortune': fortune,
      if (reputation != null) 'reputation': reputation,
      if (alignment != null) 'alignment': alignment,
      if (powerIndex != null) 'power_index': powerIndex,
      if (martialArtsJson != null) 'martial_arts_json': martialArtsJson,
      if (meridiansJson != null) 'meridians_json': meridiansJson,
      if (heartMantra != null) 'heart_mantra': heartMantra,
      if (silver != null) 'silver': silver,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CharacterTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? origin,
      Value<int>? level,
      Value<String>? attributesJson,
      Value<int>? age,
      Value<int>? health,
      Value<int>? innerEnergy,
      Value<int>? fortune,
      Value<int>? reputation,
      Value<int>? alignment,
      Value<int>? powerIndex,
      Value<String>? martialArtsJson,
      Value<String>? meridiansJson,
      Value<String?>? heartMantra,
      Value<int>? silver,
      Value<DateTime>? updatedAt}) {
    return CharacterTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      level: level ?? this.level,
      attributesJson: attributesJson ?? this.attributesJson,
      age: age ?? this.age,
      health: health ?? this.health,
      innerEnergy: innerEnergy ?? this.innerEnergy,
      fortune: fortune ?? this.fortune,
      reputation: reputation ?? this.reputation,
      alignment: alignment ?? this.alignment,
      powerIndex: powerIndex ?? this.powerIndex,
      martialArtsJson: martialArtsJson ?? this.martialArtsJson,
      meridiansJson: meridiansJson ?? this.meridiansJson,
      heartMantra: heartMantra ?? this.heartMantra,
      silver: silver ?? this.silver,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (attributesJson.present) {
      map['attributes_json'] = Variable<String>(attributesJson.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (health.present) {
      map['health'] = Variable<int>(health.value);
    }
    if (innerEnergy.present) {
      map['inner_energy'] = Variable<int>(innerEnergy.value);
    }
    if (fortune.present) {
      map['fortune'] = Variable<int>(fortune.value);
    }
    if (reputation.present) {
      map['reputation'] = Variable<int>(reputation.value);
    }
    if (alignment.present) {
      map['alignment'] = Variable<int>(alignment.value);
    }
    if (powerIndex.present) {
      map['power_index'] = Variable<int>(powerIndex.value);
    }
    if (martialArtsJson.present) {
      map['martial_arts_json'] = Variable<String>(martialArtsJson.value);
    }
    if (meridiansJson.present) {
      map['meridians_json'] = Variable<String>(meridiansJson.value);
    }
    if (heartMantra.present) {
      map['heart_mantra'] = Variable<String>(heartMantra.value);
    }
    if (silver.present) {
      map['silver'] = Variable<int>(silver.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('origin: $origin, ')
          ..write('level: $level, ')
          ..write('attributesJson: $attributesJson, ')
          ..write('age: $age, ')
          ..write('health: $health, ')
          ..write('innerEnergy: $innerEnergy, ')
          ..write('fortune: $fortune, ')
          ..write('reputation: $reputation, ')
          ..write('alignment: $alignment, ')
          ..write('powerIndex: $powerIndex, ')
          ..write('martialArtsJson: $martialArtsJson, ')
          ..write('meridiansJson: $meridiansJson, ')
          ..write('heartMantra: $heartMantra, ')
          ..write('silver: $silver, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MeridianStateTableTable extends MeridianStateTable
    with TableInfo<$MeridianStateTableTable, MeridianStateTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeridianStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _meridianIdMeta =
      const VerificationMeta('meridianId');
  @override
  late final GeneratedColumn<String> meridianId = GeneratedColumn<String>(
      'meridian_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _openedNodesMeta =
      const VerificationMeta('openedNodes');
  @override
  late final GeneratedColumn<int> openedNodes = GeneratedColumn<int>(
      'opened_nodes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, meridianId, openedNodes, isActive, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meridian_state_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<MeridianStateTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('meridian_id')) {
      context.handle(
          _meridianIdMeta,
          meridianId.isAcceptableOrUnknown(
              data['meridian_id']!, _meridianIdMeta));
    } else if (isInserting) {
      context.missing(_meridianIdMeta);
    }
    if (data.containsKey('opened_nodes')) {
      context.handle(
          _openedNodesMeta,
          openedNodes.isAcceptableOrUnknown(
              data['opened_nodes']!, _openedNodesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeridianStateTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeridianStateTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      meridianId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meridian_id'])!,
      openedNodes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}opened_nodes'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MeridianStateTableTable createAlias(String alias) {
    return $MeridianStateTableTable(attachedDatabase, alias);
  }
}

class MeridianStateTableData extends DataClass
    implements Insertable<MeridianStateTableData> {
  /// 自增主键
  final int id;

  /// 经脉 ID (对应 meridians.json 的 id, 如 'mer_yang_1')
  /// 每条经脉一行，唯一约束
  final String meridianId;

  /// 已冲开的穴位数量
  final int openedNodes;

  /// 整脉是否激活
  final bool isActive;

  /// 最后更新时间
  final DateTime updatedAt;
  const MeridianStateTableData(
      {required this.id,
      required this.meridianId,
      required this.openedNodes,
      required this.isActive,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['meridian_id'] = Variable<String>(meridianId);
    map['opened_nodes'] = Variable<int>(openedNodes);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MeridianStateTableCompanion toCompanion(bool nullToAbsent) {
    return MeridianStateTableCompanion(
      id: Value(id),
      meridianId: Value(meridianId),
      openedNodes: Value(openedNodes),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory MeridianStateTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeridianStateTableData(
      id: serializer.fromJson<int>(json['id']),
      meridianId: serializer.fromJson<String>(json['meridianId']),
      openedNodes: serializer.fromJson<int>(json['openedNodes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'meridianId': serializer.toJson<String>(meridianId),
      'openedNodes': serializer.toJson<int>(openedNodes),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MeridianStateTableData copyWith(
          {int? id,
          String? meridianId,
          int? openedNodes,
          bool? isActive,
          DateTime? updatedAt}) =>
      MeridianStateTableData(
        id: id ?? this.id,
        meridianId: meridianId ?? this.meridianId,
        openedNodes: openedNodes ?? this.openedNodes,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MeridianStateTableData copyWithCompanion(MeridianStateTableCompanion data) {
    return MeridianStateTableData(
      id: data.id.present ? data.id.value : this.id,
      meridianId:
          data.meridianId.present ? data.meridianId.value : this.meridianId,
      openedNodes:
          data.openedNodes.present ? data.openedNodes.value : this.openedNodes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeridianStateTableData(')
          ..write('id: $id, ')
          ..write('meridianId: $meridianId, ')
          ..write('openedNodes: $openedNodes, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, meridianId, openedNodes, isActive, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeridianStateTableData &&
          other.id == this.id &&
          other.meridianId == this.meridianId &&
          other.openedNodes == this.openedNodes &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class MeridianStateTableCompanion
    extends UpdateCompanion<MeridianStateTableData> {
  final Value<int> id;
  final Value<String> meridianId;
  final Value<int> openedNodes;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  const MeridianStateTableCompanion({
    this.id = const Value.absent(),
    this.meridianId = const Value.absent(),
    this.openedNodes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MeridianStateTableCompanion.insert({
    this.id = const Value.absent(),
    required String meridianId,
    this.openedNodes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : meridianId = Value(meridianId);
  static Insertable<MeridianStateTableData> custom({
    Expression<int>? id,
    Expression<String>? meridianId,
    Expression<int>? openedNodes,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meridianId != null) 'meridian_id': meridianId,
      if (openedNodes != null) 'opened_nodes': openedNodes,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MeridianStateTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? meridianId,
      Value<int>? openedNodes,
      Value<bool>? isActive,
      Value<DateTime>? updatedAt}) {
    return MeridianStateTableCompanion(
      id: id ?? this.id,
      meridianId: meridianId ?? this.meridianId,
      openedNodes: openedNodes ?? this.openedNodes,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (meridianId.present) {
      map['meridian_id'] = Variable<String>(meridianId.value);
    }
    if (openedNodes.present) {
      map['opened_nodes'] = Variable<int>(openedNodes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeridianStateTableCompanion(')
          ..write('id: $id, ')
          ..write('meridianId: $meridianId, ')
          ..write('openedNodes: $openedNodes, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RealmProgressTableTable extends RealmProgressTable
    with TableInfo<$RealmProgressTableTable, RealmProgressTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RealmProgressTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _realmIdMeta =
      const VerificationMeta('realmId');
  @override
  late final GeneratedColumn<String> realmId = GeneratedColumn<String>(
      'realm_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentLayerMeta =
      const VerificationMeta('currentLayer');
  @override
  late final GeneratedColumn<int> currentLayer = GeneratedColumn<int>(
      'current_layer', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentDifficultyMeta =
      const VerificationMeta('currentDifficulty');
  @override
  late final GeneratedColumn<int> currentDifficulty = GeneratedColumn<int>(
      'current_difficulty', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _completedEventsJsonMeta =
      const VerificationMeta('completedEventsJson');
  @override
  late final GeneratedColumn<String> completedEventsJson =
      GeneratedColumn<String>('completed_events_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _enemyCountMeta =
      const VerificationMeta('enemyCount');
  @override
  late final GeneratedColumn<int> enemyCount = GeneratedColumn<int>(
      'enemy_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _dropCountMeta =
      const VerificationMeta('dropCount');
  @override
  late final GeneratedColumn<int> dropCount = GeneratedColumn<int>(
      'drop_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        realmId,
        currentLayer,
        currentDifficulty,
        completedEventsJson,
        enemyCount,
        dropCount,
        version,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'realm_progress_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<RealmProgressTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('realm_id')) {
      context.handle(_realmIdMeta,
          realmId.isAcceptableOrUnknown(data['realm_id']!, _realmIdMeta));
    } else if (isInserting) {
      context.missing(_realmIdMeta);
    }
    if (data.containsKey('current_layer')) {
      context.handle(
          _currentLayerMeta,
          currentLayer.isAcceptableOrUnknown(
              data['current_layer']!, _currentLayerMeta));
    }
    if (data.containsKey('current_difficulty')) {
      context.handle(
          _currentDifficultyMeta,
          currentDifficulty.isAcceptableOrUnknown(
              data['current_difficulty']!, _currentDifficultyMeta));
    }
    if (data.containsKey('completed_events_json')) {
      context.handle(
          _completedEventsJsonMeta,
          completedEventsJson.isAcceptableOrUnknown(
              data['completed_events_json']!, _completedEventsJsonMeta));
    }
    if (data.containsKey('enemy_count')) {
      context.handle(
          _enemyCountMeta,
          enemyCount.isAcceptableOrUnknown(
              data['enemy_count']!, _enemyCountMeta));
    }
    if (data.containsKey('drop_count')) {
      context.handle(_dropCountMeta,
          dropCount.isAcceptableOrUnknown(data['drop_count']!, _dropCountMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {realmId};
  @override
  RealmProgressTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RealmProgressTableData(
      realmId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}realm_id'])!,
      currentLayer: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_layer'])!,
      currentDifficulty: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_difficulty'])!,
      completedEventsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}completed_events_json'])!,
      enemyCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}enemy_count'])!,
      dropCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}drop_count'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RealmProgressTableTable createAlias(String alias) {
    return $RealmProgressTableTable(attachedDatabase, alias);
  }
}

class RealmProgressTableData extends DataClass
    implements Insertable<RealmProgressTableData> {
  /// 秘境 ID
  final String realmId;

  /// 当前层数
  final int currentLayer;

  /// 当前难度 (0=普通 1=困难 2=地狱 3=炼狱)
  final int currentDifficulty;

  /// 已完成事件 ID 列表 JSON
  /// 格式: ["event_001","event_002", ...]
  final String completedEventsJson;

  /// 击杀敌人数
  final int enemyCount;

  /// 掉落物品数
  final int dropCount;

  /// 版本号 (用于 Last-Write-Wins 同步)
  final int version;

  /// 最后更新时间
  final DateTime updatedAt;
  const RealmProgressTableData(
      {required this.realmId,
      required this.currentLayer,
      required this.currentDifficulty,
      required this.completedEventsJson,
      required this.enemyCount,
      required this.dropCount,
      required this.version,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['realm_id'] = Variable<String>(realmId);
    map['current_layer'] = Variable<int>(currentLayer);
    map['current_difficulty'] = Variable<int>(currentDifficulty);
    map['completed_events_json'] = Variable<String>(completedEventsJson);
    map['enemy_count'] = Variable<int>(enemyCount);
    map['drop_count'] = Variable<int>(dropCount);
    map['version'] = Variable<int>(version);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RealmProgressTableCompanion toCompanion(bool nullToAbsent) {
    return RealmProgressTableCompanion(
      realmId: Value(realmId),
      currentLayer: Value(currentLayer),
      currentDifficulty: Value(currentDifficulty),
      completedEventsJson: Value(completedEventsJson),
      enemyCount: Value(enemyCount),
      dropCount: Value(dropCount),
      version: Value(version),
      updatedAt: Value(updatedAt),
    );
  }

  factory RealmProgressTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RealmProgressTableData(
      realmId: serializer.fromJson<String>(json['realmId']),
      currentLayer: serializer.fromJson<int>(json['currentLayer']),
      currentDifficulty: serializer.fromJson<int>(json['currentDifficulty']),
      completedEventsJson:
          serializer.fromJson<String>(json['completedEventsJson']),
      enemyCount: serializer.fromJson<int>(json['enemyCount']),
      dropCount: serializer.fromJson<int>(json['dropCount']),
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'realmId': serializer.toJson<String>(realmId),
      'currentLayer': serializer.toJson<int>(currentLayer),
      'currentDifficulty': serializer.toJson<int>(currentDifficulty),
      'completedEventsJson': serializer.toJson<String>(completedEventsJson),
      'enemyCount': serializer.toJson<int>(enemyCount),
      'dropCount': serializer.toJson<int>(dropCount),
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RealmProgressTableData copyWith(
          {String? realmId,
          int? currentLayer,
          int? currentDifficulty,
          String? completedEventsJson,
          int? enemyCount,
          int? dropCount,
          int? version,
          DateTime? updatedAt}) =>
      RealmProgressTableData(
        realmId: realmId ?? this.realmId,
        currentLayer: currentLayer ?? this.currentLayer,
        currentDifficulty: currentDifficulty ?? this.currentDifficulty,
        completedEventsJson: completedEventsJson ?? this.completedEventsJson,
        enemyCount: enemyCount ?? this.enemyCount,
        dropCount: dropCount ?? this.dropCount,
        version: version ?? this.version,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  RealmProgressTableData copyWithCompanion(RealmProgressTableCompanion data) {
    return RealmProgressTableData(
      realmId: data.realmId.present ? data.realmId.value : this.realmId,
      currentLayer: data.currentLayer.present
          ? data.currentLayer.value
          : this.currentLayer,
      currentDifficulty: data.currentDifficulty.present
          ? data.currentDifficulty.value
          : this.currentDifficulty,
      completedEventsJson: data.completedEventsJson.present
          ? data.completedEventsJson.value
          : this.completedEventsJson,
      enemyCount:
          data.enemyCount.present ? data.enemyCount.value : this.enemyCount,
      dropCount: data.dropCount.present ? data.dropCount.value : this.dropCount,
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RealmProgressTableData(')
          ..write('realmId: $realmId, ')
          ..write('currentLayer: $currentLayer, ')
          ..write('currentDifficulty: $currentDifficulty, ')
          ..write('completedEventsJson: $completedEventsJson, ')
          ..write('enemyCount: $enemyCount, ')
          ..write('dropCount: $dropCount, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(realmId, currentLayer, currentDifficulty,
      completedEventsJson, enemyCount, dropCount, version, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RealmProgressTableData &&
          other.realmId == this.realmId &&
          other.currentLayer == this.currentLayer &&
          other.currentDifficulty == this.currentDifficulty &&
          other.completedEventsJson == this.completedEventsJson &&
          other.enemyCount == this.enemyCount &&
          other.dropCount == this.dropCount &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt);
}

class RealmProgressTableCompanion
    extends UpdateCompanion<RealmProgressTableData> {
  final Value<String> realmId;
  final Value<int> currentLayer;
  final Value<int> currentDifficulty;
  final Value<String> completedEventsJson;
  final Value<int> enemyCount;
  final Value<int> dropCount;
  final Value<int> version;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RealmProgressTableCompanion({
    this.realmId = const Value.absent(),
    this.currentLayer = const Value.absent(),
    this.currentDifficulty = const Value.absent(),
    this.completedEventsJson = const Value.absent(),
    this.enemyCount = const Value.absent(),
    this.dropCount = const Value.absent(),
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RealmProgressTableCompanion.insert({
    required String realmId,
    this.currentLayer = const Value.absent(),
    this.currentDifficulty = const Value.absent(),
    this.completedEventsJson = const Value.absent(),
    this.enemyCount = const Value.absent(),
    this.dropCount = const Value.absent(),
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : realmId = Value(realmId);
  static Insertable<RealmProgressTableData> custom({
    Expression<String>? realmId,
    Expression<int>? currentLayer,
    Expression<int>? currentDifficulty,
    Expression<String>? completedEventsJson,
    Expression<int>? enemyCount,
    Expression<int>? dropCount,
    Expression<int>? version,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (realmId != null) 'realm_id': realmId,
      if (currentLayer != null) 'current_layer': currentLayer,
      if (currentDifficulty != null) 'current_difficulty': currentDifficulty,
      if (completedEventsJson != null)
        'completed_events_json': completedEventsJson,
      if (enemyCount != null) 'enemy_count': enemyCount,
      if (dropCount != null) 'drop_count': dropCount,
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RealmProgressTableCompanion copyWith(
      {Value<String>? realmId,
      Value<int>? currentLayer,
      Value<int>? currentDifficulty,
      Value<String>? completedEventsJson,
      Value<int>? enemyCount,
      Value<int>? dropCount,
      Value<int>? version,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return RealmProgressTableCompanion(
      realmId: realmId ?? this.realmId,
      currentLayer: currentLayer ?? this.currentLayer,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      completedEventsJson: completedEventsJson ?? this.completedEventsJson,
      enemyCount: enemyCount ?? this.enemyCount,
      dropCount: dropCount ?? this.dropCount,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (realmId.present) {
      map['realm_id'] = Variable<String>(realmId.value);
    }
    if (currentLayer.present) {
      map['current_layer'] = Variable<int>(currentLayer.value);
    }
    if (currentDifficulty.present) {
      map['current_difficulty'] = Variable<int>(currentDifficulty.value);
    }
    if (completedEventsJson.present) {
      map['completed_events_json'] =
          Variable<String>(completedEventsJson.value);
    }
    if (enemyCount.present) {
      map['enemy_count'] = Variable<int>(enemyCount.value);
    }
    if (dropCount.present) {
      map['drop_count'] = Variable<int>(dropCount.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RealmProgressTableCompanion(')
          ..write('realmId: $realmId, ')
          ..write('currentLayer: $currentLayer, ')
          ..write('currentDifficulty: $currentDifficulty, ')
          ..write('completedEventsJson: $completedEventsJson, ')
          ..write('enemyCount: $enemyCount, ')
          ..write('dropCount: $dropCount, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DropHistoryTableTable extends DropHistoryTable
    with TableInfo<$DropHistoryTableTable, DropHistoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DropHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _equipmentIdMeta =
      const VerificationMeta('equipmentId');
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
      'equipment_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _realmIdMeta =
      const VerificationMeta('realmId');
  @override
  late final GeneratedColumn<String> realmId = GeneratedColumn<String>(
      'realm_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<int> layer = GeneratedColumn<int>(
      'layer', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _qualityMeta =
      const VerificationMeta('quality');
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
      'quality', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, equipmentId, realmId, layer, quality, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drop_history_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<DropHistoryTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
          _equipmentIdMeta,
          equipmentId.isAcceptableOrUnknown(
              data['equipment_id']!, _equipmentIdMeta));
    } else if (isInserting) {
      context.missing(_equipmentIdMeta);
    }
    if (data.containsKey('realm_id')) {
      context.handle(_realmIdMeta,
          realmId.isAcceptableOrUnknown(data['realm_id']!, _realmIdMeta));
    } else if (isInserting) {
      context.missing(_realmIdMeta);
    }
    if (data.containsKey('layer')) {
      context.handle(
          _layerMeta, layer.isAcceptableOrUnknown(data['layer']!, _layerMeta));
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(_qualityMeta,
          quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta));
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DropHistoryTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DropHistoryTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      equipmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipment_id'])!,
      realmId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}realm_id'])!,
      layer: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}layer'])!,
      quality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quality'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $DropHistoryTableTable createAlias(String alias) {
    return $DropHistoryTableTable(attachedDatabase, alias);
  }
}

class DropHistoryTableData extends DataClass
    implements Insertable<DropHistoryTableData> {
  /// 自增主键
  final int id;

  /// 关联装备 ID
  final String equipmentId;

  /// 秘境 ID
  final String realmId;

  /// 层数
  final int layer;

  /// 品质: normal / magic / rare / unique / divine / legendary
  final String quality;

  /// 掉落时间戳
  final DateTime timestamp;
  const DropHistoryTableData(
      {required this.id,
      required this.equipmentId,
      required this.realmId,
      required this.layer,
      required this.quality,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['equipment_id'] = Variable<String>(equipmentId);
    map['realm_id'] = Variable<String>(realmId);
    map['layer'] = Variable<int>(layer);
    map['quality'] = Variable<String>(quality);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  DropHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return DropHistoryTableCompanion(
      id: Value(id),
      equipmentId: Value(equipmentId),
      realmId: Value(realmId),
      layer: Value(layer),
      quality: Value(quality),
      timestamp: Value(timestamp),
    );
  }

  factory DropHistoryTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DropHistoryTableData(
      id: serializer.fromJson<int>(json['id']),
      equipmentId: serializer.fromJson<String>(json['equipmentId']),
      realmId: serializer.fromJson<String>(json['realmId']),
      layer: serializer.fromJson<int>(json['layer']),
      quality: serializer.fromJson<String>(json['quality']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'equipmentId': serializer.toJson<String>(equipmentId),
      'realmId': serializer.toJson<String>(realmId),
      'layer': serializer.toJson<int>(layer),
      'quality': serializer.toJson<String>(quality),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  DropHistoryTableData copyWith(
          {int? id,
          String? equipmentId,
          String? realmId,
          int? layer,
          String? quality,
          DateTime? timestamp}) =>
      DropHistoryTableData(
        id: id ?? this.id,
        equipmentId: equipmentId ?? this.equipmentId,
        realmId: realmId ?? this.realmId,
        layer: layer ?? this.layer,
        quality: quality ?? this.quality,
        timestamp: timestamp ?? this.timestamp,
      );
  DropHistoryTableData copyWithCompanion(DropHistoryTableCompanion data) {
    return DropHistoryTableData(
      id: data.id.present ? data.id.value : this.id,
      equipmentId:
          data.equipmentId.present ? data.equipmentId.value : this.equipmentId,
      realmId: data.realmId.present ? data.realmId.value : this.realmId,
      layer: data.layer.present ? data.layer.value : this.layer,
      quality: data.quality.present ? data.quality.value : this.quality,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DropHistoryTableData(')
          ..write('id: $id, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('realmId: $realmId, ')
          ..write('layer: $layer, ')
          ..write('quality: $quality, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, equipmentId, realmId, layer, quality, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DropHistoryTableData &&
          other.id == this.id &&
          other.equipmentId == this.equipmentId &&
          other.realmId == this.realmId &&
          other.layer == this.layer &&
          other.quality == this.quality &&
          other.timestamp == this.timestamp);
}

class DropHistoryTableCompanion extends UpdateCompanion<DropHistoryTableData> {
  final Value<int> id;
  final Value<String> equipmentId;
  final Value<String> realmId;
  final Value<int> layer;
  final Value<String> quality;
  final Value<DateTime> timestamp;
  const DropHistoryTableCompanion({
    this.id = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.realmId = const Value.absent(),
    this.layer = const Value.absent(),
    this.quality = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  DropHistoryTableCompanion.insert({
    this.id = const Value.absent(),
    required String equipmentId,
    required String realmId,
    required int layer,
    required String quality,
    this.timestamp = const Value.absent(),
  })  : equipmentId = Value(equipmentId),
        realmId = Value(realmId),
        layer = Value(layer),
        quality = Value(quality);
  static Insertable<DropHistoryTableData> custom({
    Expression<int>? id,
    Expression<String>? equipmentId,
    Expression<String>? realmId,
    Expression<int>? layer,
    Expression<String>? quality,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (realmId != null) 'realm_id': realmId,
      if (layer != null) 'layer': layer,
      if (quality != null) 'quality': quality,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  DropHistoryTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? equipmentId,
      Value<String>? realmId,
      Value<int>? layer,
      Value<String>? quality,
      Value<DateTime>? timestamp}) {
    return DropHistoryTableCompanion(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      realmId: realmId ?? this.realmId,
      layer: layer ?? this.layer,
      quality: quality ?? this.quality,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (realmId.present) {
      map['realm_id'] = Variable<String>(realmId.value);
    }
    if (layer.present) {
      map['layer'] = Variable<int>(layer.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DropHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('realmId: $realmId, ')
          ..write('layer: $layer, ')
          ..write('quality: $quality, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $RunHistoryTableTable extends RunHistoryTable
    with TableInfo<$RunHistoryTableTable, RunHistoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _realmIdMeta =
      const VerificationMeta('realmId');
  @override
  late final GeneratedColumn<String> realmId = GeneratedColumn<String>(
      'realm_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalRoundsMeta =
      const VerificationMeta('totalRounds');
  @override
  late final GeneratedColumn<int> totalRounds = GeneratedColumn<int>(
      'total_rounds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
      'result', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bdSnapshotMeta =
      const VerificationMeta('bdSnapshot');
  @override
  late final GeneratedColumn<String> bdSnapshot = GeneratedColumn<String>(
      'bd_snapshot', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, realmId, difficulty, totalRounds, result, bdSnapshot, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_history_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<RunHistoryTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('realm_id')) {
      context.handle(_realmIdMeta,
          realmId.isAcceptableOrUnknown(data['realm_id']!, _realmIdMeta));
    } else if (isInserting) {
      context.missing(_realmIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('total_rounds')) {
      context.handle(
          _totalRoundsMeta,
          totalRounds.isAcceptableOrUnknown(
              data['total_rounds']!, _totalRoundsMeta));
    } else if (isInserting) {
      context.missing(_totalRoundsMeta);
    }
    if (data.containsKey('result')) {
      context.handle(_resultMeta,
          result.isAcceptableOrUnknown(data['result']!, _resultMeta));
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('bd_snapshot')) {
      context.handle(
          _bdSnapshotMeta,
          bdSnapshot.isAcceptableOrUnknown(
              data['bd_snapshot']!, _bdSnapshotMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunHistoryTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunHistoryTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      realmId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}realm_id'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}difficulty'])!,
      totalRounds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_rounds'])!,
      result: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}result'])!,
      bdSnapshot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bd_snapshot'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $RunHistoryTableTable createAlias(String alias) {
    return $RunHistoryTableTable(attachedDatabase, alias);
  }
}

class RunHistoryTableData extends DataClass
    implements Insertable<RunHistoryTableData> {
  /// 自增主键
  final int id;

  /// 秘境 ID
  final String realmId;

  /// 通关难度 (0=普通 1=困难 2=地狱 3=炼狱)
  final int difficulty;

  /// 总回合数
  final int totalRounds;

  /// 通关结果: victory / defeat / retreat
  final String result;

  /// BD 快照 JSON (内功+外功+装备+经脉+心法摘要)
  /// 格式: {"innerStyle":"yang","outerArts":["shaolin_quan"],"powerIndex":1850,"meridianCount":5,"heartMantra":"ruanyuekegang"}
  final String bdSnapshot;

  /// 通关时间戳
  final DateTime timestamp;
  const RunHistoryTableData(
      {required this.id,
      required this.realmId,
      required this.difficulty,
      required this.totalRounds,
      required this.result,
      required this.bdSnapshot,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['realm_id'] = Variable<String>(realmId);
    map['difficulty'] = Variable<int>(difficulty);
    map['total_rounds'] = Variable<int>(totalRounds);
    map['result'] = Variable<String>(result);
    map['bd_snapshot'] = Variable<String>(bdSnapshot);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  RunHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return RunHistoryTableCompanion(
      id: Value(id),
      realmId: Value(realmId),
      difficulty: Value(difficulty),
      totalRounds: Value(totalRounds),
      result: Value(result),
      bdSnapshot: Value(bdSnapshot),
      timestamp: Value(timestamp),
    );
  }

  factory RunHistoryTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunHistoryTableData(
      id: serializer.fromJson<int>(json['id']),
      realmId: serializer.fromJson<String>(json['realmId']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      totalRounds: serializer.fromJson<int>(json['totalRounds']),
      result: serializer.fromJson<String>(json['result']),
      bdSnapshot: serializer.fromJson<String>(json['bdSnapshot']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'realmId': serializer.toJson<String>(realmId),
      'difficulty': serializer.toJson<int>(difficulty),
      'totalRounds': serializer.toJson<int>(totalRounds),
      'result': serializer.toJson<String>(result),
      'bdSnapshot': serializer.toJson<String>(bdSnapshot),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  RunHistoryTableData copyWith(
          {int? id,
          String? realmId,
          int? difficulty,
          int? totalRounds,
          String? result,
          String? bdSnapshot,
          DateTime? timestamp}) =>
      RunHistoryTableData(
        id: id ?? this.id,
        realmId: realmId ?? this.realmId,
        difficulty: difficulty ?? this.difficulty,
        totalRounds: totalRounds ?? this.totalRounds,
        result: result ?? this.result,
        bdSnapshot: bdSnapshot ?? this.bdSnapshot,
        timestamp: timestamp ?? this.timestamp,
      );
  RunHistoryTableData copyWithCompanion(RunHistoryTableCompanion data) {
    return RunHistoryTableData(
      id: data.id.present ? data.id.value : this.id,
      realmId: data.realmId.present ? data.realmId.value : this.realmId,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      totalRounds:
          data.totalRounds.present ? data.totalRounds.value : this.totalRounds,
      result: data.result.present ? data.result.value : this.result,
      bdSnapshot:
          data.bdSnapshot.present ? data.bdSnapshot.value : this.bdSnapshot,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunHistoryTableData(')
          ..write('id: $id, ')
          ..write('realmId: $realmId, ')
          ..write('difficulty: $difficulty, ')
          ..write('totalRounds: $totalRounds, ')
          ..write('result: $result, ')
          ..write('bdSnapshot: $bdSnapshot, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, realmId, difficulty, totalRounds, result, bdSnapshot, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunHistoryTableData &&
          other.id == this.id &&
          other.realmId == this.realmId &&
          other.difficulty == this.difficulty &&
          other.totalRounds == this.totalRounds &&
          other.result == this.result &&
          other.bdSnapshot == this.bdSnapshot &&
          other.timestamp == this.timestamp);
}

class RunHistoryTableCompanion extends UpdateCompanion<RunHistoryTableData> {
  final Value<int> id;
  final Value<String> realmId;
  final Value<int> difficulty;
  final Value<int> totalRounds;
  final Value<String> result;
  final Value<String> bdSnapshot;
  final Value<DateTime> timestamp;
  const RunHistoryTableCompanion({
    this.id = const Value.absent(),
    this.realmId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.totalRounds = const Value.absent(),
    this.result = const Value.absent(),
    this.bdSnapshot = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  RunHistoryTableCompanion.insert({
    this.id = const Value.absent(),
    required String realmId,
    required int difficulty,
    required int totalRounds,
    required String result,
    this.bdSnapshot = const Value.absent(),
    this.timestamp = const Value.absent(),
  })  : realmId = Value(realmId),
        difficulty = Value(difficulty),
        totalRounds = Value(totalRounds),
        result = Value(result);
  static Insertable<RunHistoryTableData> custom({
    Expression<int>? id,
    Expression<String>? realmId,
    Expression<int>? difficulty,
    Expression<int>? totalRounds,
    Expression<String>? result,
    Expression<String>? bdSnapshot,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (realmId != null) 'realm_id': realmId,
      if (difficulty != null) 'difficulty': difficulty,
      if (totalRounds != null) 'total_rounds': totalRounds,
      if (result != null) 'result': result,
      if (bdSnapshot != null) 'bd_snapshot': bdSnapshot,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  RunHistoryTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? realmId,
      Value<int>? difficulty,
      Value<int>? totalRounds,
      Value<String>? result,
      Value<String>? bdSnapshot,
      Value<DateTime>? timestamp}) {
    return RunHistoryTableCompanion(
      id: id ?? this.id,
      realmId: realmId ?? this.realmId,
      difficulty: difficulty ?? this.difficulty,
      totalRounds: totalRounds ?? this.totalRounds,
      result: result ?? this.result,
      bdSnapshot: bdSnapshot ?? this.bdSnapshot,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (realmId.present) {
      map['realm_id'] = Variable<String>(realmId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (totalRounds.present) {
      map['total_rounds'] = Variable<int>(totalRounds.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (bdSnapshot.present) {
      map['bd_snapshot'] = Variable<String>(bdSnapshot.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('realmId: $realmId, ')
          ..write('difficulty: $difficulty, ')
          ..write('totalRounds: $totalRounds, ')
          ..write('result: $result, ')
          ..write('bdSnapshot: $bdSnapshot, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'settings_table';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsTableData> instance,
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
  SettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsTableData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsTableData extends DataClass
    implements Insertable<SettingsTableData> {
  /// 设置键名
  final String key;

  /// 设置值 (JSON 字符串，支持任意类型)
  final String value;
  const SettingsTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsTableData(
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

  SettingsTableData copyWith({String? key, String? value}) => SettingsTableData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingsTableData copyWithCompanion(SettingsTableCompanion data) {
    return SettingsTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableData(')
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
      (other is SettingsTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingsTableData> custom({
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

  SettingsTableCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsTableCompanion(
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
    return (StringBuffer('SettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EquipmentTableTable equipmentTable = $EquipmentTableTable(this);
  late final $CharacterTableTable characterTable = $CharacterTableTable(this);
  late final $MeridianStateTableTable meridianStateTable =
      $MeridianStateTableTable(this);
  late final $RealmProgressTableTable realmProgressTable =
      $RealmProgressTableTable(this);
  late final $DropHistoryTableTable dropHistoryTable =
      $DropHistoryTableTable(this);
  late final $RunHistoryTableTable runHistoryTable =
      $RunHistoryTableTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final EquipmentDao equipmentDao = EquipmentDao(this as AppDatabase);
  late final CharacterDao characterDao = CharacterDao(this as AppDatabase);
  late final MeridianDao meridianDao = MeridianDao(this as AppDatabase);
  late final RealmDao realmDao = RealmDao(this as AppDatabase);
  late final DropDao dropDao = DropDao(this as AppDatabase);
  late final RunDao runDao = RunDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        equipmentTable,
        characterTable,
        meridianStateTable,
        realmProgressTable,
        dropHistoryTable,
        runHistoryTable,
        settingsTable
      ];
}

typedef $$EquipmentTableTableCreateCompanionBuilder = EquipmentTableCompanion
    Function({
  required String id,
  required String baseId,
  required String quality,
  required String slot,
  required String name,
  Value<String> affixesJson,
  Value<int> reinforceLevel,
  Value<String?> meridianSeedId,
  required int itemLevel,
  Value<bool> isEquipped,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$EquipmentTableTableUpdateCompanionBuilder = EquipmentTableCompanion
    Function({
  Value<String> id,
  Value<String> baseId,
  Value<String> quality,
  Value<String> slot,
  Value<String> name,
  Value<String> affixesJson,
  Value<int> reinforceLevel,
  Value<String?> meridianSeedId,
  Value<int> itemLevel,
  Value<bool> isEquipped,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$EquipmentTableTableFilterComposer
    extends Composer<_$AppDatabase, $EquipmentTableTable> {
  $$EquipmentTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseId => $composableBuilder(
      column: $table.baseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get affixesJson => $composableBuilder(
      column: $table.affixesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reinforceLevel => $composableBuilder(
      column: $table.reinforceLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meridianSeedId => $composableBuilder(
      column: $table.meridianSeedId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemLevel => $composableBuilder(
      column: $table.itemLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEquipped => $composableBuilder(
      column: $table.isEquipped, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$EquipmentTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EquipmentTableTable> {
  $$EquipmentTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseId => $composableBuilder(
      column: $table.baseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get affixesJson => $composableBuilder(
      column: $table.affixesJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reinforceLevel => $composableBuilder(
      column: $table.reinforceLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meridianSeedId => $composableBuilder(
      column: $table.meridianSeedId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemLevel => $composableBuilder(
      column: $table.itemLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEquipped => $composableBuilder(
      column: $table.isEquipped, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$EquipmentTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EquipmentTableTable> {
  $$EquipmentTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseId =>
      $composableBuilder(column: $table.baseId, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get affixesJson => $composableBuilder(
      column: $table.affixesJson, builder: (column) => column);

  GeneratedColumn<int> get reinforceLevel => $composableBuilder(
      column: $table.reinforceLevel, builder: (column) => column);

  GeneratedColumn<String> get meridianSeedId => $composableBuilder(
      column: $table.meridianSeedId, builder: (column) => column);

  GeneratedColumn<int> get itemLevel =>
      $composableBuilder(column: $table.itemLevel, builder: (column) => column);

  GeneratedColumn<bool> get isEquipped => $composableBuilder(
      column: $table.isEquipped, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EquipmentTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EquipmentTableTable,
    EquipmentTableData,
    $$EquipmentTableTableFilterComposer,
    $$EquipmentTableTableOrderingComposer,
    $$EquipmentTableTableAnnotationComposer,
    $$EquipmentTableTableCreateCompanionBuilder,
    $$EquipmentTableTableUpdateCompanionBuilder,
    (
      EquipmentTableData,
      BaseReferences<_$AppDatabase, $EquipmentTableTable, EquipmentTableData>
    ),
    EquipmentTableData,
    PrefetchHooks Function()> {
  $$EquipmentTableTableTableManager(
      _$AppDatabase db, $EquipmentTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EquipmentTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EquipmentTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EquipmentTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> baseId = const Value.absent(),
            Value<String> quality = const Value.absent(),
            Value<String> slot = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> affixesJson = const Value.absent(),
            Value<int> reinforceLevel = const Value.absent(),
            Value<String?> meridianSeedId = const Value.absent(),
            Value<int> itemLevel = const Value.absent(),
            Value<bool> isEquipped = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EquipmentTableCompanion(
            id: id,
            baseId: baseId,
            quality: quality,
            slot: slot,
            name: name,
            affixesJson: affixesJson,
            reinforceLevel: reinforceLevel,
            meridianSeedId: meridianSeedId,
            itemLevel: itemLevel,
            isEquipped: isEquipped,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String baseId,
            required String quality,
            required String slot,
            required String name,
            Value<String> affixesJson = const Value.absent(),
            Value<int> reinforceLevel = const Value.absent(),
            Value<String?> meridianSeedId = const Value.absent(),
            required int itemLevel,
            Value<bool> isEquipped = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EquipmentTableCompanion.insert(
            id: id,
            baseId: baseId,
            quality: quality,
            slot: slot,
            name: name,
            affixesJson: affixesJson,
            reinforceLevel: reinforceLevel,
            meridianSeedId: meridianSeedId,
            itemLevel: itemLevel,
            isEquipped: isEquipped,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EquipmentTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EquipmentTableTable,
    EquipmentTableData,
    $$EquipmentTableTableFilterComposer,
    $$EquipmentTableTableOrderingComposer,
    $$EquipmentTableTableAnnotationComposer,
    $$EquipmentTableTableCreateCompanionBuilder,
    $$EquipmentTableTableUpdateCompanionBuilder,
    (
      EquipmentTableData,
      BaseReferences<_$AppDatabase, $EquipmentTableTable, EquipmentTableData>
    ),
    EquipmentTableData,
    PrefetchHooks Function()>;
typedef $$CharacterTableTableCreateCompanionBuilder = CharacterTableCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String> origin,
  Value<int> level,
  Value<String> attributesJson,
  Value<int> age,
  Value<int> health,
  Value<int> innerEnergy,
  Value<int> fortune,
  Value<int> reputation,
  Value<int> alignment,
  Value<int> powerIndex,
  Value<String> martialArtsJson,
  Value<String> meridiansJson,
  Value<String?> heartMantra,
  Value<int> silver,
  Value<DateTime> updatedAt,
});
typedef $$CharacterTableTableUpdateCompanionBuilder = CharacterTableCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> origin,
  Value<int> level,
  Value<String> attributesJson,
  Value<int> age,
  Value<int> health,
  Value<int> innerEnergy,
  Value<int> fortune,
  Value<int> reputation,
  Value<int> alignment,
  Value<int> powerIndex,
  Value<String> martialArtsJson,
  Value<String> meridiansJson,
  Value<String?> heartMantra,
  Value<int> silver,
  Value<DateTime> updatedAt,
});

class $$CharacterTableTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterTableTable> {
  $$CharacterTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get health => $composableBuilder(
      column: $table.health, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get innerEnergy => $composableBuilder(
      column: $table.innerEnergy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fortune => $composableBuilder(
      column: $table.fortune, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reputation => $composableBuilder(
      column: $table.reputation, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get alignment => $composableBuilder(
      column: $table.alignment, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get powerIndex => $composableBuilder(
      column: $table.powerIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get martialArtsJson => $composableBuilder(
      column: $table.martialArtsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meridiansJson => $composableBuilder(
      column: $table.meridiansJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get heartMantra => $composableBuilder(
      column: $table.heartMantra, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get silver => $composableBuilder(
      column: $table.silver, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CharacterTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterTableTable> {
  $$CharacterTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get health => $composableBuilder(
      column: $table.health, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get innerEnergy => $composableBuilder(
      column: $table.innerEnergy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fortune => $composableBuilder(
      column: $table.fortune, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reputation => $composableBuilder(
      column: $table.reputation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get alignment => $composableBuilder(
      column: $table.alignment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get powerIndex => $composableBuilder(
      column: $table.powerIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get martialArtsJson => $composableBuilder(
      column: $table.martialArtsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meridiansJson => $composableBuilder(
      column: $table.meridiansJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get heartMantra => $composableBuilder(
      column: $table.heartMantra, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get silver => $composableBuilder(
      column: $table.silver, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CharacterTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterTableTable> {
  $$CharacterTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<int> get health =>
      $composableBuilder(column: $table.health, builder: (column) => column);

  GeneratedColumn<int> get innerEnergy => $composableBuilder(
      column: $table.innerEnergy, builder: (column) => column);

  GeneratedColumn<int> get fortune =>
      $composableBuilder(column: $table.fortune, builder: (column) => column);

  GeneratedColumn<int> get reputation => $composableBuilder(
      column: $table.reputation, builder: (column) => column);

  GeneratedColumn<int> get alignment =>
      $composableBuilder(column: $table.alignment, builder: (column) => column);

  GeneratedColumn<int> get powerIndex => $composableBuilder(
      column: $table.powerIndex, builder: (column) => column);

  GeneratedColumn<String> get martialArtsJson => $composableBuilder(
      column: $table.martialArtsJson, builder: (column) => column);

  GeneratedColumn<String> get meridiansJson => $composableBuilder(
      column: $table.meridiansJson, builder: (column) => column);

  GeneratedColumn<String> get heartMantra => $composableBuilder(
      column: $table.heartMantra, builder: (column) => column);

  GeneratedColumn<int> get silver =>
      $composableBuilder(column: $table.silver, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CharacterTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CharacterTableTable,
    CharacterTableData,
    $$CharacterTableTableFilterComposer,
    $$CharacterTableTableOrderingComposer,
    $$CharacterTableTableAnnotationComposer,
    $$CharacterTableTableCreateCompanionBuilder,
    $$CharacterTableTableUpdateCompanionBuilder,
    (
      CharacterTableData,
      BaseReferences<_$AppDatabase, $CharacterTableTable, CharacterTableData>
    ),
    CharacterTableData,
    PrefetchHooks Function()> {
  $$CharacterTableTableTableManager(
      _$AppDatabase db, $CharacterTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> origin = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<String> attributesJson = const Value.absent(),
            Value<int> age = const Value.absent(),
            Value<int> health = const Value.absent(),
            Value<int> innerEnergy = const Value.absent(),
            Value<int> fortune = const Value.absent(),
            Value<int> reputation = const Value.absent(),
            Value<int> alignment = const Value.absent(),
            Value<int> powerIndex = const Value.absent(),
            Value<String> martialArtsJson = const Value.absent(),
            Value<String> meridiansJson = const Value.absent(),
            Value<String?> heartMantra = const Value.absent(),
            Value<int> silver = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CharacterTableCompanion(
            id: id,
            name: name,
            origin: origin,
            level: level,
            attributesJson: attributesJson,
            age: age,
            health: health,
            innerEnergy: innerEnergy,
            fortune: fortune,
            reputation: reputation,
            alignment: alignment,
            powerIndex: powerIndex,
            martialArtsJson: martialArtsJson,
            meridiansJson: meridiansJson,
            heartMantra: heartMantra,
            silver: silver,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> origin = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<String> attributesJson = const Value.absent(),
            Value<int> age = const Value.absent(),
            Value<int> health = const Value.absent(),
            Value<int> innerEnergy = const Value.absent(),
            Value<int> fortune = const Value.absent(),
            Value<int> reputation = const Value.absent(),
            Value<int> alignment = const Value.absent(),
            Value<int> powerIndex = const Value.absent(),
            Value<String> martialArtsJson = const Value.absent(),
            Value<String> meridiansJson = const Value.absent(),
            Value<String?> heartMantra = const Value.absent(),
            Value<int> silver = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CharacterTableCompanion.insert(
            id: id,
            name: name,
            origin: origin,
            level: level,
            attributesJson: attributesJson,
            age: age,
            health: health,
            innerEnergy: innerEnergy,
            fortune: fortune,
            reputation: reputation,
            alignment: alignment,
            powerIndex: powerIndex,
            martialArtsJson: martialArtsJson,
            meridiansJson: meridiansJson,
            heartMantra: heartMantra,
            silver: silver,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CharacterTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CharacterTableTable,
    CharacterTableData,
    $$CharacterTableTableFilterComposer,
    $$CharacterTableTableOrderingComposer,
    $$CharacterTableTableAnnotationComposer,
    $$CharacterTableTableCreateCompanionBuilder,
    $$CharacterTableTableUpdateCompanionBuilder,
    (
      CharacterTableData,
      BaseReferences<_$AppDatabase, $CharacterTableTable, CharacterTableData>
    ),
    CharacterTableData,
    PrefetchHooks Function()>;
typedef $$MeridianStateTableTableCreateCompanionBuilder
    = MeridianStateTableCompanion Function({
  Value<int> id,
  required String meridianId,
  Value<int> openedNodes,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
});
typedef $$MeridianStateTableTableUpdateCompanionBuilder
    = MeridianStateTableCompanion Function({
  Value<int> id,
  Value<String> meridianId,
  Value<int> openedNodes,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
});

class $$MeridianStateTableTableFilterComposer
    extends Composer<_$AppDatabase, $MeridianStateTableTable> {
  $$MeridianStateTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meridianId => $composableBuilder(
      column: $table.meridianId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openedNodes => $composableBuilder(
      column: $table.openedNodes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$MeridianStateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MeridianStateTableTable> {
  $$MeridianStateTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meridianId => $composableBuilder(
      column: $table.meridianId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openedNodes => $composableBuilder(
      column: $table.openedNodes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MeridianStateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeridianStateTableTable> {
  $$MeridianStateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get meridianId => $composableBuilder(
      column: $table.meridianId, builder: (column) => column);

  GeneratedColumn<int> get openedNodes => $composableBuilder(
      column: $table.openedNodes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MeridianStateTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MeridianStateTableTable,
    MeridianStateTableData,
    $$MeridianStateTableTableFilterComposer,
    $$MeridianStateTableTableOrderingComposer,
    $$MeridianStateTableTableAnnotationComposer,
    $$MeridianStateTableTableCreateCompanionBuilder,
    $$MeridianStateTableTableUpdateCompanionBuilder,
    (
      MeridianStateTableData,
      BaseReferences<_$AppDatabase, $MeridianStateTableTable,
          MeridianStateTableData>
    ),
    MeridianStateTableData,
    PrefetchHooks Function()> {
  $$MeridianStateTableTableTableManager(
      _$AppDatabase db, $MeridianStateTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeridianStateTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeridianStateTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeridianStateTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> meridianId = const Value.absent(),
            Value<int> openedNodes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MeridianStateTableCompanion(
            id: id,
            meridianId: meridianId,
            openedNodes: openedNodes,
            isActive: isActive,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String meridianId,
            Value<int> openedNodes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MeridianStateTableCompanion.insert(
            id: id,
            meridianId: meridianId,
            openedNodes: openedNodes,
            isActive: isActive,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MeridianStateTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MeridianStateTableTable,
    MeridianStateTableData,
    $$MeridianStateTableTableFilterComposer,
    $$MeridianStateTableTableOrderingComposer,
    $$MeridianStateTableTableAnnotationComposer,
    $$MeridianStateTableTableCreateCompanionBuilder,
    $$MeridianStateTableTableUpdateCompanionBuilder,
    (
      MeridianStateTableData,
      BaseReferences<_$AppDatabase, $MeridianStateTableTable,
          MeridianStateTableData>
    ),
    MeridianStateTableData,
    PrefetchHooks Function()>;
typedef $$RealmProgressTableTableCreateCompanionBuilder
    = RealmProgressTableCompanion Function({
  required String realmId,
  Value<int> currentLayer,
  Value<int> currentDifficulty,
  Value<String> completedEventsJson,
  Value<int> enemyCount,
  Value<int> dropCount,
  Value<int> version,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$RealmProgressTableTableUpdateCompanionBuilder
    = RealmProgressTableCompanion Function({
  Value<String> realmId,
  Value<int> currentLayer,
  Value<int> currentDifficulty,
  Value<String> completedEventsJson,
  Value<int> enemyCount,
  Value<int> dropCount,
  Value<int> version,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$RealmProgressTableTableFilterComposer
    extends Composer<_$AppDatabase, $RealmProgressTableTable> {
  $$RealmProgressTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get realmId => $composableBuilder(
      column: $table.realmId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentLayer => $composableBuilder(
      column: $table.currentLayer, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentDifficulty => $composableBuilder(
      column: $table.currentDifficulty,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completedEventsJson => $composableBuilder(
      column: $table.completedEventsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get enemyCount => $composableBuilder(
      column: $table.enemyCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dropCount => $composableBuilder(
      column: $table.dropCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$RealmProgressTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RealmProgressTableTable> {
  $$RealmProgressTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get realmId => $composableBuilder(
      column: $table.realmId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentLayer => $composableBuilder(
      column: $table.currentLayer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentDifficulty => $composableBuilder(
      column: $table.currentDifficulty,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completedEventsJson => $composableBuilder(
      column: $table.completedEventsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get enemyCount => $composableBuilder(
      column: $table.enemyCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dropCount => $composableBuilder(
      column: $table.dropCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RealmProgressTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RealmProgressTableTable> {
  $$RealmProgressTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get realmId =>
      $composableBuilder(column: $table.realmId, builder: (column) => column);

  GeneratedColumn<int> get currentLayer => $composableBuilder(
      column: $table.currentLayer, builder: (column) => column);

  GeneratedColumn<int> get currentDifficulty => $composableBuilder(
      column: $table.currentDifficulty, builder: (column) => column);

  GeneratedColumn<String> get completedEventsJson => $composableBuilder(
      column: $table.completedEventsJson, builder: (column) => column);

  GeneratedColumn<int> get enemyCount => $composableBuilder(
      column: $table.enemyCount, builder: (column) => column);

  GeneratedColumn<int> get dropCount =>
      $composableBuilder(column: $table.dropCount, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RealmProgressTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RealmProgressTableTable,
    RealmProgressTableData,
    $$RealmProgressTableTableFilterComposer,
    $$RealmProgressTableTableOrderingComposer,
    $$RealmProgressTableTableAnnotationComposer,
    $$RealmProgressTableTableCreateCompanionBuilder,
    $$RealmProgressTableTableUpdateCompanionBuilder,
    (
      RealmProgressTableData,
      BaseReferences<_$AppDatabase, $RealmProgressTableTable,
          RealmProgressTableData>
    ),
    RealmProgressTableData,
    PrefetchHooks Function()> {
  $$RealmProgressTableTableTableManager(
      _$AppDatabase db, $RealmProgressTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RealmProgressTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RealmProgressTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RealmProgressTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> realmId = const Value.absent(),
            Value<int> currentLayer = const Value.absent(),
            Value<int> currentDifficulty = const Value.absent(),
            Value<String> completedEventsJson = const Value.absent(),
            Value<int> enemyCount = const Value.absent(),
            Value<int> dropCount = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RealmProgressTableCompanion(
            realmId: realmId,
            currentLayer: currentLayer,
            currentDifficulty: currentDifficulty,
            completedEventsJson: completedEventsJson,
            enemyCount: enemyCount,
            dropCount: dropCount,
            version: version,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String realmId,
            Value<int> currentLayer = const Value.absent(),
            Value<int> currentDifficulty = const Value.absent(),
            Value<String> completedEventsJson = const Value.absent(),
            Value<int> enemyCount = const Value.absent(),
            Value<int> dropCount = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RealmProgressTableCompanion.insert(
            realmId: realmId,
            currentLayer: currentLayer,
            currentDifficulty: currentDifficulty,
            completedEventsJson: completedEventsJson,
            enemyCount: enemyCount,
            dropCount: dropCount,
            version: version,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RealmProgressTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RealmProgressTableTable,
    RealmProgressTableData,
    $$RealmProgressTableTableFilterComposer,
    $$RealmProgressTableTableOrderingComposer,
    $$RealmProgressTableTableAnnotationComposer,
    $$RealmProgressTableTableCreateCompanionBuilder,
    $$RealmProgressTableTableUpdateCompanionBuilder,
    (
      RealmProgressTableData,
      BaseReferences<_$AppDatabase, $RealmProgressTableTable,
          RealmProgressTableData>
    ),
    RealmProgressTableData,
    PrefetchHooks Function()>;
typedef $$DropHistoryTableTableCreateCompanionBuilder
    = DropHistoryTableCompanion Function({
  Value<int> id,
  required String equipmentId,
  required String realmId,
  required int layer,
  required String quality,
  Value<DateTime> timestamp,
});
typedef $$DropHistoryTableTableUpdateCompanionBuilder
    = DropHistoryTableCompanion Function({
  Value<int> id,
  Value<String> equipmentId,
  Value<String> realmId,
  Value<int> layer,
  Value<String> quality,
  Value<DateTime> timestamp,
});

class $$DropHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $DropHistoryTableTable> {
  $$DropHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipmentId => $composableBuilder(
      column: $table.equipmentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get realmId => $composableBuilder(
      column: $table.realmId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get layer => $composableBuilder(
      column: $table.layer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
}

class $$DropHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DropHistoryTableTable> {
  $$DropHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipmentId => $composableBuilder(
      column: $table.equipmentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get realmId => $composableBuilder(
      column: $table.realmId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get layer => $composableBuilder(
      column: $table.layer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
}

class $$DropHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DropHistoryTableTable> {
  $$DropHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get equipmentId => $composableBuilder(
      column: $table.equipmentId, builder: (column) => column);

  GeneratedColumn<String> get realmId =>
      $composableBuilder(column: $table.realmId, builder: (column) => column);

  GeneratedColumn<int> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$DropHistoryTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DropHistoryTableTable,
    DropHistoryTableData,
    $$DropHistoryTableTableFilterComposer,
    $$DropHistoryTableTableOrderingComposer,
    $$DropHistoryTableTableAnnotationComposer,
    $$DropHistoryTableTableCreateCompanionBuilder,
    $$DropHistoryTableTableUpdateCompanionBuilder,
    (
      DropHistoryTableData,
      BaseReferences<_$AppDatabase, $DropHistoryTableTable,
          DropHistoryTableData>
    ),
    DropHistoryTableData,
    PrefetchHooks Function()> {
  $$DropHistoryTableTableTableManager(
      _$AppDatabase db, $DropHistoryTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DropHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DropHistoryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DropHistoryTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> equipmentId = const Value.absent(),
            Value<String> realmId = const Value.absent(),
            Value<int> layer = const Value.absent(),
            Value<String> quality = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              DropHistoryTableCompanion(
            id: id,
            equipmentId: equipmentId,
            realmId: realmId,
            layer: layer,
            quality: quality,
            timestamp: timestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String equipmentId,
            required String realmId,
            required int layer,
            required String quality,
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              DropHistoryTableCompanion.insert(
            id: id,
            equipmentId: equipmentId,
            realmId: realmId,
            layer: layer,
            quality: quality,
            timestamp: timestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DropHistoryTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DropHistoryTableTable,
    DropHistoryTableData,
    $$DropHistoryTableTableFilterComposer,
    $$DropHistoryTableTableOrderingComposer,
    $$DropHistoryTableTableAnnotationComposer,
    $$DropHistoryTableTableCreateCompanionBuilder,
    $$DropHistoryTableTableUpdateCompanionBuilder,
    (
      DropHistoryTableData,
      BaseReferences<_$AppDatabase, $DropHistoryTableTable,
          DropHistoryTableData>
    ),
    DropHistoryTableData,
    PrefetchHooks Function()>;
typedef $$RunHistoryTableTableCreateCompanionBuilder = RunHistoryTableCompanion
    Function({
  Value<int> id,
  required String realmId,
  required int difficulty,
  required int totalRounds,
  required String result,
  Value<String> bdSnapshot,
  Value<DateTime> timestamp,
});
typedef $$RunHistoryTableTableUpdateCompanionBuilder = RunHistoryTableCompanion
    Function({
  Value<int> id,
  Value<String> realmId,
  Value<int> difficulty,
  Value<int> totalRounds,
  Value<String> result,
  Value<String> bdSnapshot,
  Value<DateTime> timestamp,
});

class $$RunHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $RunHistoryTableTable> {
  $$RunHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get realmId => $composableBuilder(
      column: $table.realmId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalRounds => $composableBuilder(
      column: $table.totalRounds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bdSnapshot => $composableBuilder(
      column: $table.bdSnapshot, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
}

class $$RunHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RunHistoryTableTable> {
  $$RunHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get realmId => $composableBuilder(
      column: $table.realmId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalRounds => $composableBuilder(
      column: $table.totalRounds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bdSnapshot => $composableBuilder(
      column: $table.bdSnapshot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
}

class $$RunHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunHistoryTableTable> {
  $$RunHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get realmId =>
      $composableBuilder(column: $table.realmId, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<int> get totalRounds => $composableBuilder(
      column: $table.totalRounds, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<String> get bdSnapshot => $composableBuilder(
      column: $table.bdSnapshot, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$RunHistoryTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RunHistoryTableTable,
    RunHistoryTableData,
    $$RunHistoryTableTableFilterComposer,
    $$RunHistoryTableTableOrderingComposer,
    $$RunHistoryTableTableAnnotationComposer,
    $$RunHistoryTableTableCreateCompanionBuilder,
    $$RunHistoryTableTableUpdateCompanionBuilder,
    (
      RunHistoryTableData,
      BaseReferences<_$AppDatabase, $RunHistoryTableTable, RunHistoryTableData>
    ),
    RunHistoryTableData,
    PrefetchHooks Function()> {
  $$RunHistoryTableTableTableManager(
      _$AppDatabase db, $RunHistoryTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunHistoryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunHistoryTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> realmId = const Value.absent(),
            Value<int> difficulty = const Value.absent(),
            Value<int> totalRounds = const Value.absent(),
            Value<String> result = const Value.absent(),
            Value<String> bdSnapshot = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              RunHistoryTableCompanion(
            id: id,
            realmId: realmId,
            difficulty: difficulty,
            totalRounds: totalRounds,
            result: result,
            bdSnapshot: bdSnapshot,
            timestamp: timestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String realmId,
            required int difficulty,
            required int totalRounds,
            required String result,
            Value<String> bdSnapshot = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              RunHistoryTableCompanion.insert(
            id: id,
            realmId: realmId,
            difficulty: difficulty,
            totalRounds: totalRounds,
            result: result,
            bdSnapshot: bdSnapshot,
            timestamp: timestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RunHistoryTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RunHistoryTableTable,
    RunHistoryTableData,
    $$RunHistoryTableTableFilterComposer,
    $$RunHistoryTableTableOrderingComposer,
    $$RunHistoryTableTableAnnotationComposer,
    $$RunHistoryTableTableCreateCompanionBuilder,
    $$RunHistoryTableTableUpdateCompanionBuilder,
    (
      RunHistoryTableData,
      BaseReferences<_$AppDatabase, $RunHistoryTableTable, RunHistoryTableData>
    ),
    RunHistoryTableData,
    PrefetchHooks Function()>;
typedef $$SettingsTableTableCreateCompanionBuilder = SettingsTableCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableTableUpdateCompanionBuilder = SettingsTableCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
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

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
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

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
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

class $$SettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsTableData,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsTableData,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>
    ),
    SettingsTableData,
    PrefetchHooks Function()> {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsTableCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsTableCompanion.insert(
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

typedef $$SettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsTableData,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsTableData,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>
    ),
    SettingsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EquipmentTableTableTableManager get equipmentTable =>
      $$EquipmentTableTableTableManager(_db, _db.equipmentTable);
  $$CharacterTableTableTableManager get characterTable =>
      $$CharacterTableTableTableManager(_db, _db.characterTable);
  $$MeridianStateTableTableTableManager get meridianStateTable =>
      $$MeridianStateTableTableTableManager(_db, _db.meridianStateTable);
  $$RealmProgressTableTableTableManager get realmProgressTable =>
      $$RealmProgressTableTableTableManager(_db, _db.realmProgressTable);
  $$DropHistoryTableTableTableManager get dropHistoryTable =>
      $$DropHistoryTableTableTableManager(_db, _db.dropHistoryTable);
  $$RunHistoryTableTableTableManager get runHistoryTable =>
      $$RunHistoryTableTableTableManager(_db, _db.runHistoryTable);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}
