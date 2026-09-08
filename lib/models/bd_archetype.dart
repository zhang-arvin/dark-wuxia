// =============================================================================
// models/bd_archetype.dart — BD流派画像（从 battle_engine 平移，批次1）
//
// 纯数据模型：零引擎依赖。
// =============================================================================

// =============================================================================
// BD流派画像（DESIGN.md 3.4.4）
// =============================================================================

/// BD流派画像分析结果
class BDArchetype {
  final String name;
  final String description;

  const BDArchetype({required this.name, required this.description});

  @override
  String toString() => 'BDArchetype($name: $description)';
}

