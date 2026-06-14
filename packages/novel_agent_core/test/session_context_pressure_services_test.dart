import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Session context pressure services', () {
    test(
      'estimates system prompt, tool payload and framing conservatively',
      () {
        // 中文注释: 这里验证估算器会把系统提示、工具载荷和 framing 开销拆开估算，而且更长内容一定更大。
        const estimator = SessionTokenBudgetEstimatorService();
        final shortText = estimator.estimateTextTokens('Hello world');
        final longText = estimator.estimateTextTokens('Hello world ' * 20);
        final toolPayload = <String, Object?>{
          'tool_calls': <Object?>[
            <String, Object?>{
              'id': 'tool-1',
              'name': 'read_file',
              'arguments': '{"path":"src/main.rs","mode":"read"}',
            },
          ],
          'tool_result': <String, Object?>{
            'content': 'result ' * 40,
            'status': 'success',
          },
        };

        final toolTokens = estimator.estimateToolPayloadTokens(toolPayload);
        final systemTokens = estimator.estimateSystemPromptTokens('系统提示词');
        final messages = <Object?>[
          <String, Object?>{'role': 'user', 'content': '先检查上下文。'},
          <String, Object?>{
            'role': 'assistant',
            'tool_calls': <Object?>[
              <String, Object?>{
                'id': 'tool-1',
                'name': 'read_file',
                'arguments': '{"path":"src/main.rs"}',
              },
            ],
          },
        ];
        final framingTokens = estimator.estimateFramingTokens(messages);
        final estimate = estimator.estimate(
          systemPrompt: '系统提示词',
          messages: messages,
          baseFramingTokens: 16,
        );

        expect(shortText, greaterThan(0));
        expect(longText, greaterThan(shortText));
        expect(systemTokens, greaterThan(0));
        expect(toolTokens, greaterThan(shortText));
        expect(framingTokens, greaterThan(0));
        expect(estimate.systemPromptTokens, systemTokens);
        expect(estimate.messageTokens, greaterThan(0));
        expect(estimate.framingTokens, greaterThan(0));
        expect(
          estimate.totalInputTokens,
          greaterThan(estimate.systemPromptTokens),
        );
      },
    );

    test(
      'produces safe warning and critical pressure snapshots from settings',
      () {
        // 中文注释: 这里验证压力服务只做快照组合，不改动预算语义，也能稳定产出 safe / warning / critical。
        const estimator = SessionTokenBudgetEstimatorService();
        const pressureService = SessionContextPressureService(
          estimatorService: estimator,
        );
        final settings = SessionTokenBudgetSettings(
          modelContextWindowTokens: 10000,
          reservedOutputTokens: 1000,
          warningThresholdRatio: 0.75,
          criticalThresholdRatio: 0.9,
        );
        final safeSnapshot = pressureService.snapshot(
          settings: settings,
          systemPrompt: '系统提示',
          messages: <Object?>[
            <String, Object?>{'role': 'user', 'content': '短句'},
          ],
        );
        final warningSnapshot = pressureService.snapshot(
          settings: settings,
          systemPrompt: '系统提示',
        messages: <Object?>[
          <String, Object?>{'role': 'user', 'content': '中等长度内容 ' * 1260},
        ],
      );
        final criticalSnapshot = pressureService.snapshot(
          settings: settings,
          systemPrompt: '系统提示',
        messages: <Object?>[
          <String, Object?>{'role': 'user', 'content': '中等长度内容 ' * 1350},
        ],
      );

        expect(safeSnapshot.pressureLevel, SessionContextPressureLevel.safe);
        expect(
          warningSnapshot.pressureLevel,
          SessionContextPressureLevel.warning,
        );
        expect(
          criticalSnapshot.pressureLevel,
          SessionContextPressureLevel.critical,
        );
        expect(safeSnapshot.toJson(), containsPair('pressure_level', 'safe'));
        expect(
          criticalSnapshot.toJson(),
          containsPair('pressure_level', 'critical'),
        );
      },
    );

    test('prefers working context messages when evaluating session records', () {
      // 中文注释: 这里验证 session record 级别压力判断优先读 working context，而不是旧 transcript 或 legacy context。
      const pressureService = SessionContextPressureService();
      final settings = SessionTokenBudgetSettings(
        modelContextWindowTokens: 8000,
        reservedOutputTokens: 1000,
        warningThresholdRatio: 0.75,
        criticalThresholdRatio: 0.9,
      );
      final record = <String, Object?>{
        SessionRecordConstants.workingContextMessagesField: <Object?>[
          <String, Object?>{'role': 'user', 'content': '工作窗口内容 ' * 20},
        ],
        SessionRecordConstants.transcriptMessagesField: <Object?>[
          <String, Object?>{'role': 'user', 'content': '完整历史内容 ' * 600},
        ],
        SessionRecordConstants.legacyContextMessagesField: <Object?>[
          <String, Object?>{'role': 'user', 'content': '旧桥接内容 ' * 800},
        ],
      };

      final snapshot = pressureService.snapshotFromSessionRecord(
        record,
        settings: settings,
        systemPrompt: '系统提示',
      );

      expect(snapshot.pressureLevel, SessionContextPressureLevel.safe);
      expect(snapshot.estimate.messageTokens, greaterThan(0));
      expect(snapshot.estimate.totalInputTokens, lessThan(2000));
    });
  });
}
