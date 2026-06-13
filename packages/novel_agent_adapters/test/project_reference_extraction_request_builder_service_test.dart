import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectReferenceExtractionRequestBuilderService', () {
    const service = ProjectReferenceExtractionRequestBuilderService();

    test('fills stable defaults for gui-like execution input', () {
      final request = service.build(
        const ProjectReferenceExtractionRequestInput(
          sourceFilePath: 'references/files/reference_source.txt',
        ),
      );

      expect(request.sourceFilePath, contains('reference_source.txt'));
      expect(request.displayName, '参考资料提取：reference_source.txt');
      expect(request.sourceLanguage, isEmpty);
      expect(request.targetLanguage, 'zh-CN');
      expect(request.maxChapterEntries, 6);
      expect(request.maxEntityEntries, 6);
      expect(request.exportBundle, isTrue);
      expect(request.attachToProject, isTrue);
      expect(request.projectMountedEntries, isTrue);
      expect(request.strategyProfileId, isEmpty);
      expect(request.availableContextChars, 0);
      expect(request.additionalStrategyProfiles, isEmpty);
    });

    test(
      'preserves explicit overrides and normalizes invalid numeric input',
      () {
        final request = service.build(
          const ProjectReferenceExtractionRequestInput(
            sourceFilePath: 'references/files/sample_zh.txt',
            displayName: '自定义提取',
            sourceLanguage: 'ja',
            targetLanguage: 'zh-TW',
            maxChapterEntries: 0,
            maxEntityEntries: -2,
            exportBundle: false,
            attachToProject: false,
            projectMountedEntries: false,
            explicitProjectionConfirmationGranted: false,
            bundleOutputDirectory: 'bundle_out',
            strategyProfileId:
                ReferenceExtractionBuiltinStrategyProfileIds.factFocused,
            availableContextChars: 64000,
            additionalStrategyProfiles: <ReferenceExtractionStrategyProfile>[
              ReferenceExtractionStrategyProfile(
                profileId: 'reference_extraction.custom_dense',
              ),
            ],
          ),
        );

        expect(request.displayName, '自定义提取');
        expect(request.sourceLanguage, 'ja');
        expect(request.targetLanguage, 'zh-TW');
        expect(request.maxChapterEntries, 6);
        expect(request.maxEntityEntries, 6);
        expect(request.exportBundle, isFalse);
        expect(request.attachToProject, isFalse);
        expect(request.projectMountedEntries, isFalse);
        expect(request.explicitProjectionConfirmationGranted, isFalse);
        expect(request.bundleOutputDirectory, 'bundle_out');
        expect(
          request.strategyProfileId,
          ReferenceExtractionBuiltinStrategyProfileIds.factFocused,
        );
        expect(request.availableContextChars, 64000);
        expect(request.additionalStrategyProfiles, hasLength(1));
        expect(
          request.additionalStrategyProfiles.single.profileId,
          'reference_extraction.custom_dense',
        );
      },
    );
  });
}
