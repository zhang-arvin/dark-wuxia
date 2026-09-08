// =============================================================================
// 对应 DESIGN.md 章节：3.1 角色系统 — 3.1.1 五维属性 & 3.1.2 衍生属性
//
// 五维属性：
//   臂力(BODY)   — 外功伤害基数、生命上限
//   身法(AGI)    — 先手值、闪避率、暴击率
//   悟性(WIS)    — 修炼速度、武功兼容性
//   根骨(CON)    — 内力上限、内力恢复、生命恢复
//   福缘(LUCK)   — 掉落率加成(=D2的MF)、奇遇触发率
//
// 衍生属性：
//   战力指数(POWER) — 综合评分，一键看成长
//   内力(INNER)     — 根骨×等级×内功加成
//   生命(HP)        — 臂力×等级×装备加成
//   先手值(INIT)    — 身法×轻功加成
//   闪避(DODGE)     — 身法×轻功×经脉加成
// =============================================================================

/// 五维属性模型
///
/// 每个属性为整数，基础值由出身决定，成长由等级和装备提供。
/// 手写 == / hashCode 用于 Riverpod 状态比较。
class Attributes {
  /// 臂力 — 外功伤害基数、生命上限
  final int body;

  /// 身法 — 先手值、闪避率、暴击率
  final int agi;

  /// 悟性 — 修炼速度、武功兼容性
  final int wis;

  /// 根骨 — 内力上限、内力恢复、生命恢复
  final int con;

  /// 福缘 — 掉落率加成(=D2的MF)、奇遇触发率
  final int luck;

  const Attributes({
    required this.body,
    required this.agi,
    required this.wis,
    required this.con,
    required this.luck,
  });

  /// 默认初始属性（新建角色）
  factory Attributes.defaultValues() => const Attributes(
        body: 10,
        agi: 10,
        wis: 10,
        con: 10,
        luck: 5,
      );

  /// 从 JSON 反序列化
  factory Attributes.fromJson(Map<String, dynamic> json) => Attributes(
        body: json['body'] as int,
        agi: json['agi'] as int,
        wis: json['wis'] as int,
        con: json['con'] as int,
        luck: json['luck'] as int,
      );

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'body': body,
        'agi': agi,
        'wis': wis,
        'con': con,
        'luck': luck,
      };

  /// 属性加法（装备词缀叠加用）
  Attributes operator +(Attributes other) => Attributes(
        body: body + other.body,
        agi: agi + other.agi,
        wis: wis + other.wis,
        con: con + other.con,
        luck: luck + other.luck,
      );

  /// 属性乘法（用于倍率加成）
  Attributes operator *(double factor) => Attributes(
        body: (body * factor).round(),
        agi: (agi * factor).round(),
        wis: (wis * factor).round(),
        con: (con * factor).round(),
        luck: (luck * factor).round(),
      );

  /// 复制并修改部分属性
  Attributes copyWith({
    int? body,
    int? agi,
    int? wis,
    int? con,
    int? luck,
  }) =>
      Attributes(
        body: body ?? this.body,
        agi: agi ?? this.agi,
        wis: wis ?? this.wis,
        con: con ?? this.con,
        luck: luck ?? this.luck,
      );

  /// 五维总和
  int get total => body + agi + wis + con + luck;

  /// 计算战力指数（综合评分，DESIGN.md 3.10.1）
  ///
  /// 公式：臂力×3 + 身法×2 + 悟性×2 + 根骨×3 + 福缘×1
  int get powerContribution => body * 3 + agi * 2 + wis * 2 + con * 3 + luck;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attributes &&
          body == other.body &&
          agi == other.agi &&
          wis == other.wis &&
          con == other.con &&
          luck == other.luck;

  @override
  int get hashCode => Object.hash(body, agi, wis, con, luck);

  @override
  String toString() => 'Attributes(body: $body, agi: $agi, wis: $wis, con: $con, luck: $luck)';
}
