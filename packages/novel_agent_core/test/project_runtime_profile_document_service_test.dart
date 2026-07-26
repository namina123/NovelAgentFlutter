import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectRuntimeProfileDocumentService', () {
    test('does not assign a long-task baseline to a non-long project', () {
      final service = ProjectRuntimeProfileDocumentService();

      final profile = service.buildProfile(
        projectType: 'novel',
        runtimeBaselineId: 'continuous_autonomous',
      );

      expect(profile.projectType, 'novel');
      expect(profile.runtimeBaselineId, isEmpty);
      expect(profile.initialRunOptions['unattended'], isFalse);
      expect(profile.initialRunOptions['auto_advance_chapters'], isFalse);
    });

    test('long task contract requires a registered long-novel baseline', () {
      const service = LongTaskProjectContractService();

      final missingBaseline = service.assess(
        project: const ProjectDescriptor(
          id: 'missing_baseline',
          name: '缺失基准',
          rootPath: '/tmp/missing_baseline',
          projectType: 'long_novel',
        ),
      );
      final nonLong = service.assess(
        project: const ProjectDescriptor(
          id: 'ordinary',
          name: '普通项目',
          rootPath: '/tmp/ordinary',
          projectType: 'novel',
          runtimeBaselineId: 'continuous_autonomous',
        ),
      );

      expect(missingBaseline.isAllowed, isFalse);
      expect(missingBaseline.errorCode, 'long_task_runtime_baseline_missing');
      expect(nonLong.isAllowed, isFalse);
      expect(nonLong.errorCode, 'long_task_unsupported_project_type');
    });

    test(
      'long task contract rejects a requested baseline different from manifest',
      () {
        const service = LongTaskProjectContractService();

        final assessment = service.assess(
          project: const ProjectDescriptor(
            id: 'baseline_mismatch',
            name: '基准不一致',
            rootPath: '/tmp/baseline_mismatch',
            projectType: 'long_novel',
            runtimeBaselineId: 'continuous_autonomous',
          ),
          requestedRuntimeBaselineId: 'chapter_collaboration_autorun',
        );

        expect(assessment.isAllowed, isFalse);
        expect(assessment.errorCode, 'long_task_runtime_baseline_mismatch');
      },
    );

    test(
      'repairs an incompatible baseline and its derived run options on decode',
      () {
        // 中文注释: profile 是 manifest 的派生快照；损坏或手工编辑不能把长任务能力注入普通项目。
        final service = ProjectRuntimeProfileDocumentService();

        final profile = service.parse('''
{
  "project_type": "novel",
  "runtime_baseline_id": "continuous_autonomous",
  "runtime_mode": "seed_to_full_novel",
  "initial_run_options": {
    "runtime_baseline_id": "continuous_autonomous",
    "unattended": true,
    "auto_advance_chapters": true
  }
}
''');

        expect(profile.runtimeBaselineId, isEmpty);
        expect(profile.initialRunOptions['runtime_baseline_id'], isEmpty);
        expect(profile.initialRunOptions['unattended'], isFalse);
        expect(profile.initialRunOptions['auto_advance_chapters'], isFalse);
      },
    );

    test(
      'normalizes a manually constructed incompatible profile before encoding',
      () {
        final service = ProjectRuntimeProfileDocumentService();
        const profile = ProjectRuntimeProfile(
          projectType: 'knowledge_base',
          runtimeBaselineId: 'chapter_collaboration_autorun',
          runtimeMode: 'human_outline_ai_draft',
          initialRunOptions: <String, Object?>{
            'runtime_baseline_id': 'chapter_collaboration_autorun',
            'unattended': true,
          },
        );

        final decoded = service.parse(service.encode(profile));

        expect(decoded.projectType, 'knowledge_base');
        expect(decoded.runtimeBaselineId, isEmpty);
        expect(decoded.initialRunOptions['runtime_baseline_id'], isEmpty);
        expect(decoded.initialRunOptions['unattended'], isFalse);
      },
    );
  });
}
