import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointDriftSignalService', () {
    final service = LongTaskCheckpointDriftSignalService();

    test('builds style world and entity signals for sample chapter', () {
      final signals = service.buildSignals(
        taskType: 'chapter',
        stage: 'sample',
        memorySections: const <JsonMap>[
          <String, Object?>{'title': '风格锚点'},
          <String, Object?>{'title': '世界硬约束'},
          <String, Object?>{'title': '角色/身份锚点'},
        ],
        outputPaths: const <String>['drafts/ch01.md'],
      );

      expect(
        signals.map((item) => item['domain']),
        containsAll(<Object?>['style', 'world', 'entity']),
      );
      expect(
        signals.any(
          (item) =>
              ValueReaders.stringValue(item['domain']) == 'style' &&
              ValueReaders.stringValue(item['severity']) == 'high',
        ),
        isTrue,
      );
    });
  });
}
