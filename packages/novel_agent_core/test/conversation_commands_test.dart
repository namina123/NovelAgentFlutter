import 'dart:async';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

/// 记录所有后端调用并允许按动作注入自定义产出，供命令纯逻辑测试使用。
class _FakeBackend implements ConversationCommandBackend {
  _FakeBackend({
    this.outcomes = const <String, ConversationCommandBackendOutcome>{},
  });

  final Map<String, ConversationCommandBackendOutcome> outcomes;
  String? lastSetMode;
  String? lastSetGoalText;
  int compactCalls = 0;
  int statsCalls = 0;
  int clearCalls = 0;
  int exitCalls = 0;

  ConversationCommandBackendOutcome _resolve(String key, JsonMap fallbackRecord) {
    return outcomes[key] ??
        ConversationCommandBackendOutcome(updatedSessionRecord: fallbackRecord);
  }

  @override
  Future<ConversationCommandBackendOutcome> compact(JsonMap sessionRecord) async {
    compactCalls += 1;
    return _resolve('compact', sessionRecord);
  }

  @override
  Future<ConversationCommandBackendOutcome> stats(JsonMap sessionRecord) async {
    statsCalls += 1;
    return _resolve('stats', sessionRecord);
  }

  @override
  Future<ConversationCommandBackendOutcome> setMode(
    JsonMap sessionRecord,
    String mode,
  ) async {
    lastSetMode = mode;
    return _resolve('setMode', <String, Object?>{...sessionRecord, 'mode': mode});
  }

  @override
  Future<ConversationCommandBackendOutcome> setGoalText(
    JsonMap sessionRecord,
    String text,
  ) async {
    lastSetGoalText = text;
    return _resolve(
      'setGoalText',
      <String, Object?>{
        ...sessionRecord,
        SessionRecordConstants.conversationGoalField: text,
      },
    );
  }

  @override
  Future<ConversationCommandBackendOutcome> clearContext(
    JsonMap sessionRecord,
  ) async {
    clearCalls += 1;
    return _resolve('clear', sessionRecord);
  }

  @override
  Future<ConversationCommandBackendOutcome> exitSession(
    JsonMap sessionRecord,
  ) async {
    exitCalls += 1;
    return _resolve('exit', sessionRecord);
  }
}

ConversationCommandDispatcher _dispatcher(
  _FakeBackend backend, {
  JsonMap sessionRecord = const <String, Object?>{},
}) {
  final registry = ConversationCommandRegistry();
  registerBuiltinConversationCommands(registry);
  return ConversationCommandDispatcher(
    registry: registry,
    contextFactory: (rawArgs) => ConversationCommandContext(
      project: const ProjectDescriptor(id: 'p', name: 'demo', rootPath: '/demo'),
      sessionRecord: sessionRecord,
      rawArgs: rawArgs,
      backend: backend,
    ),
  );
}

void main() {
  group('ConversationCommandRegistry', () {
    test('lookup by name and alias; all() dedupes and sorts', () {
      final registry = ConversationCommandRegistry();
      registerBuiltinConversationCommands(registry);
      expect(registry.lookup('help')?.name, 'help');
      expect(registry.lookup('?')?.name, 'help');
      expect(
        registry.all().map((command) => command.name).toList(),
        <String>['clear', 'compact', 'goal', 'help', 'stats'],
      );
    });
  });

  group('builtinConversationCommandSuggestions', () {
    test('lists the core builtin commands for GUI completion', () {
      final suggestions = builtinConversationCommandSuggestions();
      expect(suggestions, hasLength(5));
      expect(
        suggestions.map((s) => s.name).toSet(),
        <String>{'help', 'goal', 'compact', 'stats', 'clear'},
      );
    });
  });

  group('ConversationCommandDispatcher', () {
    test('non-slash input passes through', () async {
      final result = await _dispatcher(_FakeBackend()).dispatch('写下一章');
      expect(result.kind, ConversationCommandOutcomeKind.passThrough);
    });

    test('empty slash lists available commands', () async {
      final result = await _dispatcher(_FakeBackend()).dispatch('/');
      expect(result.kind, ConversationCommandOutcomeKind.unknown);
      expect(result.message, contains('/help'));
      expect(result.message, contains('/goal'));
    });

    test('unknown command reports and hints', () async {
      final result = await _dispatcher(_FakeBackend()).dispatch('/nope');
      expect(result.kind, ConversationCommandOutcomeKind.unknown);
      expect(result.message, contains('未知指令'));
      expect(result.message, contains('/help'));
    });

    test('help lists all commands', () async {
      final result = await _dispatcher(_FakeBackend()).dispatch('/help');
      expect(result.kind, ConversationCommandOutcomeKind.handled);
      expect(result.message, contains('/goal'));
      expect(result.message, contains('/compact'));
    });
  });

  group('GoalConversationCommand', () {
    test('no args lists modes and shows current', () async {
      final result = await _dispatcher(
        _FakeBackend(),
        sessionRecord: const <String, Object?>{'mode': 'smart_opening'},
      ).dispatch('/goal');
      expect(result.kind, ConversationCommandOutcomeKind.handled);
      expect(result.message, contains('当前模式'));
      expect(result.message, contains('智能开局'));
      expect(result.message, contains('单章创作'));
    });

    test('matching mode label switches mode via backend', () async {
      final backend = _FakeBackend(
        outcomes: <String, ConversationCommandBackendOutcome>{
          'setMode': ConversationCommandBackendOutcome(
            updatedSessionRecord: const <String, Object?>{
              'mode': 'continue_writing',
            },
            persist: true,
          ),
        },
      );
      final result = await _dispatcher(backend).dispatch('/goal 续写');
      expect(backend.lastSetMode, 'continue_writing');
      expect(backend.lastSetGoalText, isNull);
      expect(result.message, contains('继续创作'));
      expect(result.persist, isTrue);
      expect(result.updatedSessionRecord?['mode'], 'continue_writing');
    });

    test('matching mode constant value switches mode', () async {
      final backend = _FakeBackend();
      await _dispatcher(backend).dispatch('/goal chapter_draft');
      expect(backend.lastSetMode, 'chapter_draft');
    });

    test('non-matching arg sets free-text goal', () async {
      final backend = _FakeBackend();
      final result = await _dispatcher(backend).dispatch('/goal 收束第三章伏笔');
      expect(backend.lastSetGoalText, '收束第三章伏笔');
      expect(backend.lastSetMode, isNull);
      expect(
        result.updatedSessionRecord?[SessionRecordConstants.conversationGoalField],
        '收束第三章伏笔',
      );
    });
  });

  group('context management commands', () {
    test('stats surfaces public_summary and detail payload', () async {
      final backend = _FakeBackend(
        outcomes: <String, ConversationCommandBackendOutcome>{
          'stats': ConversationCommandBackendOutcome(
            updatedSessionRecord: const <String, Object?>{},
            detail: <String, Object?>{
              'public_summary': '压力 safe｜已用 1000',
              'pressure_snapshot': <String, Object?>{'pressure_level': 'safe'},
            },
          ),
        },
      );
      final result = await _dispatcher(backend).dispatch('/stats');
      expect(backend.statsCalls, 1);
      expect(result.kind, ConversationCommandOutcomeKind.handled);
      expect(result.message, '压力 safe｜已用 1000');
      expect(result.payload?['pressure_snapshot'], isA<Map<String, Object?>>());
    });

    test('compact calls backend and carries decision payload', () async {
      final backend = _FakeBackend(
        outcomes: <String, ConversationCommandBackendOutcome>{
          'compact': ConversationCommandBackendOutcome(
            updatedSessionRecord: <String, Object?>{
              'id': 's1',
              'compression_count': 1,
            },
            persist: true,
            detail: <String, Object?>{
              'compaction_decision': <String, Object?>{
                'action_kind': 'compact_now',
              },
            },
          ),
        },
      );
      final result = await _dispatcher(backend).dispatch('/compact');
      expect(backend.compactCalls, 1);
      expect(result.persist, isTrue);
      expect(result.updatedSessionRecord?['compression_count'], 1);
      expect(result.payload?['action_kind'], 'compact_now');
    });

    test('clear calls backend.clearContext', () async {
      final backend = _FakeBackend();
      final result = await _dispatcher(backend).dispatch('/clear');
      expect(backend.clearCalls, 1);
      expect(result.kind, ConversationCommandOutcomeKind.handled);
    });
  });
}
