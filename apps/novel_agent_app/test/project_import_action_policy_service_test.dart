import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_import_action_policy_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProjectImportActionPolicyService', () {
    test(
      'book deconstruction project defaults to source archive root and auto enables for a single markdown file',
      () {
        final service = ProjectImportActionPolicyService();

        final policy = service.build(
          projectType: BookDeconstructionConstants.projectTypeId,
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
          sourcePaths: const <String>['C:/imports/reference_book.md'],
        );

        expect(
          policy.resolvedTargetDirectory,
          const ProjectContentPathPolicyService().directoryForContentType(
            'source_original',
          ),
        );
        expect(policy.canAutoDeconstruct, isTrue);
        expect(policy.autoDeconstruct, isTrue);
        expect(
          service.autoDeconstructionPreviewPath(
            projectType: BookDeconstructionConstants.projectTypeId,
            sourcePath: 'C:/imports/reference_book.md',
          ),
          'analysis/deconstruction/book_deconstruction_reference_book.md',
        );
        expect(policy.canSmartAnalyze, isFalse);
        expect(policy.smartAnalysis, isFalse);
      },
    );

    test(
      'epub source also enables auto deconstruction for deconstruction project',
      () {
        final service = ProjectImportActionPolicyService();

        final policy = service.build(
          projectType: BookDeconstructionConstants.projectTypeId,
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
          sourcePaths: const <String>['C:/imports/reference_book.epub'],
        );

        expect(policy.canAutoDeconstruct, isTrue);
        expect(policy.autoDeconstruct, isTrue);
        expect(
          policy.outputHint,
          contains(
            'analysis/deconstruction/book_deconstruction_reference_book.md',
          ),
        );
        expect(policy.outputHint, contains('拆书专用模型'));
      },
    );

    test(
      'normal project falls back to assets and keeps auto deconstruction off by default',
      () {
        final service = ProjectImportActionPolicyService();

        final policy = service.build(
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
          sourcePaths: const <String>[],
        );

        expect(policy.resolvedTargetDirectory, 'assets');
        expect(policy.canAutoDeconstruct, isFalse);
        expect(policy.autoDeconstruct, isFalse);
        expect(policy.outputHint, contains('导入文件或文件夹后'));
        expect(policy.outputHint, contains('智能分析'));
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
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
          sourcePaths: const <String>[
            'C:/imports/book_a.md',
            'C:/imports/book_b.md',
          ],
          requestedAutoDeconstruct: true,
        );

        expect(policy.canAutoDeconstruct, isFalse);
        expect(policy.autoDeconstruct, isFalse);
        expect(policy.fileSelectionHint, contains('已选择 2 个来源'));
        expect(policy.outputHint, contains('智能分析'));
      },
    );

    test(
      'sqlite novel defaults imports into imports root instead of assets',
      () {
        final service = ProjectImportActionPolicyService();

        final policy = service.build(
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          sourcePaths: const <String>[],
        );

        expect(policy.resolvedTargetDirectory, 'imports');
      },
    );
  });
}
