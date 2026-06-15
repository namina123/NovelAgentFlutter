import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_import_action_policy_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProjectImportActionPolicyService', () {
    test(
      'book deconstruction project defaults to chapters and auto enables for a single markdown file',
      () {
        final service = ProjectImportActionPolicyService();

        final policy = service.build(
          projectType: BookDeconstructionConstants.projectTypeId,
          sourcePaths: const <String>['C:/imports/reference_book.md'],
        );

        expect(
          policy.resolvedTargetDirectory,
          ProjectContentPathPolicyService.chaptersRoot,
        );
        expect(policy.canAutoDeconstruct, isTrue);
        expect(policy.autoDeconstruct, isTrue);
        expect(
          service.autoDeconstructionPreviewPath(
            projectType: BookDeconstructionConstants.projectTypeId,
            sourcePath: 'C:/imports/reference_book.md',
          ),
          'chapters/book_deconstruction_reference_book.md',
        );
        expect(policy.canSmartAnalyze, isFalse);
        expect(policy.smartAnalysis, isFalse);
      },
    );

    test(
      'normal project falls back to assets and keeps auto deconstruction off by default',
      () {
        final service = ProjectImportActionPolicyService();

        final policy = service.build(
          projectType: 'novel',
          sourcePaths: const <String>[],
        );

        expect(policy.resolvedTargetDirectory, 'assets');
        expect(policy.canAutoDeconstruct, isFalse);
        expect(policy.autoDeconstruct, isFalse);
        expect(policy.outputHint, contains('.txt / .md / .markdown'));
        expect(policy.canSmartAnalyze, isTrue);
        expect(policy.smartAnalysis, isFalse);
      },
    );

    test(
      'multi-file selections disable auto deconstruction even when requested',
      () {
        final service = ProjectImportActionPolicyService();

        final policy = service.build(
          projectType: 'novel',
          sourcePaths: const <String>[
            'C:/imports/book_a.md',
            'C:/imports/book_b.md',
          ],
          requestedAutoDeconstruct: true,
        );

        expect(policy.canAutoDeconstruct, isFalse);
        expect(policy.autoDeconstruct, isFalse);
        expect(policy.fileSelectionHint, contains('自动拆书仅支持单个文本或 Markdown 文件'));
        expect(policy.outputHint, contains('当前选择不支持自动拆书'));
      },
    );
  });
}
