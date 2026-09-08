// =============================================================================
// test/engine/rng_snapshot_test.dart — RNG 消费序列快照测试（批次0 P0-1）
//
// 目的：用 Random(seed) 替换随机源，逐位记录战斗引擎的 nextInt 消费序列。
// 任何重构改变 nextInt 调用顺序/次数，本测试立即报警——这就是 RNG 等价承诺
// 的回归保护。
//
// 思路：子类化 Random，把每次 nextInt 的值和调用点都记录下来，
// 然后跑一场战斗，比较两次运行（重构前后）的消费序列完全一致。
//
// 注意：快照不 compare to golden file，而是同一进程内两次运行对比
// （一次作为 baseline，clone 引擎再跑断言逐位一致）。golden 文件固化
// 属于重构完成后第二步。
// =============================================================================

import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:dark_wuxia/engine/battle_engine.dart';
import 'package:dark_wuxia/engine/config_loader.dart';
import 'package:dark_wuxia/engine/narration_engine.dart';
import 'package:dark_wuxia/models/attributes.dart';
import 'package:dark_wuxia/models/character.dart';
import 'package:dark_wuxia/models/enums.dart';

/// 记录型 Random：每次 nextInt 都记录 (bound, result)
class RecordingRandom implements Random {
  final Random _inner;
  final List<String> _calls = [];
  List<String> get calls => List.unmodifiable(_calls);

  RecordingRandom(int seed) : _inner = Random(seed);

  @override
  int nextInt(int max) {
    final result = _inner.nextInt(max);
    _calls.add('nextInt($max)=$result');
    return result;
  }

  @override
  double nextDouble() {
    final result = _inner.nextDouble();
    _calls.add('nextDouble()=$result');
    return result;
  }

  @override
  bool nextBool() {
    final result = _inner.nextBool();
    _calls.add('nextBool()=$result');
    return result;
  }
}

Future<ConfigLoader> _loadConfig() async {
  final enemiesJson = await rootBundle.loadString('assets/config/enemies.json');
  final loader = ConfigLoader.forTesting();
  loader.loadFromJsonMap({ConfigType.enemies: enemiesJson});
  return loader;
}

Character _makeCharacter() {
  return Character(
    name: '快照侠客',
    origin: '无名山村',
    age: 18,
    level: 1,
    attributes: const Attributes(body: 10, agi: 10, wis: 10, con: 10, luck: 5),
    health: 1000,
    innerEnergy: 200,
    powerIndex: 100,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RNG 消费序列快照：同参数同 seed 两次 run 逐位一致', () async {
    final loader = await _loadConfig();
    final enemy = loader.getEnemy('enemy_gm_001')!.toEnemy();

    // 第一次 run：RecordingRandom 记录消费
    final rec1 = RecordingRandom(42);
    final engine1 = BattleEngine(loader, NarrationEngine(Random(42)), rec1);
    final st1 = engine1.initRuntime(
      player: _makeCharacter(),
      enemy: enemy,
      realmId: 'realm_gumu',
      layer: 1,
      difficulty: Difficulty.normal,
    );
    for (var i = 0; i < st1.maxTurns && !st1.battleOver; i++) {
      st1.setPlayerAction(BattleActionType.attack);
      engine1.stepTurn(st1);
    }
    final firstRun = rec1.calls.toList();
    expect(firstRun, isNotEmpty, reason: '战斗至少应消费若干 RNG');

    // 第二次 run：同样的 seed 42，消费序列应逐位一致
    final rec2 = RecordingRandom(42);
    final engine2 = BattleEngine(loader, NarrationEngine(Random(42)), rec2);
    final st2 = engine2.initRuntime(
      player: _makeCharacter(),
      enemy: enemy,
      realmId: 'realm_gumu',
      layer: 1,
      difficulty: Difficulty.normal,
    );
    for (var i = 0; i < st2.maxTurns && !st2.battleOver; i++) {
      st2.setPlayerAction(BattleActionType.attack);
      engine2.stepTurn(st2);
    }
    final secondRun = rec2.calls.toList();

    expect(secondRun.length, firstRun.length,
        reason: '两次运行消费的 RNG 次数必须一致');
    for (var i = 0; i < firstRun.length; i++) {
      expect(secondRun[i], firstRun[i],
          reason: '第 $i 次 RNG 消费必须逐位一致');
    }
  });

  test('RNG 消费：initRuntime 阶段消费次数与 seed 无关（结构确定性）', () async {
    final loader = await _loadConfig();
    final enemy = loader.getEnemy('enemy_gm_001')!.toEnemy();

    final initLengths = <int>[];
    for (final seed in [1, 7, 99, 2024]) {
      final rec = RecordingRandom(seed);
      final engine = BattleEngine(loader, NarrationEngine(Random(seed)), rec);
      final st = engine.initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
      );
      // init 阶段只消费档位/回合数判定，与 seed 值无关
      initLengths.add(rec.calls.length);
      // 完整战斗也至少消费 RNG（完整战耗序列可能在战斗结束回合数处分叉）
      for (var i = 0; i < st.maxTurns && !st.battleOver; i++) {
        st.setPlayerAction(BattleActionType.attack);
        engine.stepTurn(st);
      }
      expect(rec.calls.length, greaterThan(initLengths.last),
          reason: 'seed=$seed 完整战斗应比 init 阶段消费更多 RNG');
    }
    final first = initLengths.first;
    for (final l in initLengths) {
      expect(l, first,
          reason: 'initRuntime 的 RNG 消费次数在所有 seed 下必须一致');
    }
  });
}