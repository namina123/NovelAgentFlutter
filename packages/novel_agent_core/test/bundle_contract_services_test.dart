import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Bundle contract services', () {
    test(
      'style bundle carries stable header and passes checksum validation',
      () {
        // 中文注释: 这里验证风格包会自动补版本头和 checksum，确保后续不是“能导出但不可校验”的空合同。
        final documentService = StyleBundleDocumentService();
        final validationService = BundleValidationService();
        final bundle = documentService.buildBundle(
          styles: const <StyleProfile>[
            StyleProfile(
              id: 'serial_style',
              displayName: '连载风格',
              summary: '克制、冷静、偏悬疑。',
            ),
          ],
          title: '风格测试包',
          createdAt: '2026-05-25T12:00:00Z',
        );

        expect(bundle['kind'], BundleKind.styleBundle);
        expect(bundle['checksum'], isNotEmpty);
        final validation = validationService.validateBundle(
          bundle,
          expectedKind: BundleKind.styleBundle,
        );
        expect(validation.ok, isTrue);
      },
    );

    test('character bundle preview reports project conflicts separately', () {
      final documentService = CharacterCardBundleDocumentService();
      final previewService = CharacterCardBundleImportPreviewService();
      final bundleContent = documentService.encodeBundle(
        documentService.buildBundle(
          characters: const <CharacterProfile>[
            CharacterProfile(
              id: 'hero_01',
              displayName: '主角',
              summary: '谨慎、敏感、行动晚熟。',
            ),
          ],
          organizations: const <OrganizationProfile>[
            OrganizationProfile(
              id: 'sect_01',
              displayName: '夜雨会',
              summary: '主角早期接触的地下组织。',
            ),
          ],
          title: '角色测试包',
          createdAt: '2026-05-25T12:10:00Z',
        ),
      );

      final preview = previewService.previewBundle(
        bundleContent: bundleContent,
        existingCharacters: const <JsonMap>[
          <String, Object?>{'id': 'hero_01', 'display_name': '旧主角'},
        ],
        existingOrganizations: const <JsonMap>[],
        overwrite: false,
      );

      expect(preview.totalCount, 2);
      expect(preview.conflictCount, 1);
      expect(preview.newCount, 1);
      expect(preview.items.first.status, 'project_conflict');
      expect(preview.items.last.status, 'new');
    });

    test('prompt template bundle preview reuses template path rules', () {
      final documentService = PromptTemplateBundleDocumentService();
      final previewService = PromptTemplateBundleImportPreviewService();
      final bundleContent = documentService.encodeBundle(
        documentService.buildBundle(
          templates: const <JsonMap>[
            <String, Object?>{
              'id': 'chapter_rewrite',
              'name': '章节重写模板',
              'scope': 'task',
              'content': '请根据 {{analysis_summary}} 重写章节。',
            },
          ],
          title: '模板测试包',
          createdAt: '2026-05-25T12:20:00Z',
        ),
      );

      final preview = previewService.previewBundle(
        bundleContent: bundleContent,
        existingTemplates: const <JsonMap>[
          <String, Object?>{'id': 'chapter_rewrite', 'name': '旧模板'},
        ],
      );

      expect(preview.totalCount, 1);
      expect(preview.items.single.targetPath, 'prompts/chapter_rewrite.json');
      expect(preview.items.single.status, 'project_conflict');
    });

    test(
      'project package contains manifest runtime profile and asset/template payloads',
      () {
        final documentService = ProjectPackageDocumentService();
        final validationService = BundleValidationService();
        final manifest = const ProjectManifest(
          title: '示例项目',
          projectType: 'standard_novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
          runtimeBaselineId: '',
        );
        final runtimeProfile = ProjectRuntimeProfileDocumentService()
            .buildProfile(
              projectType: 'long_form_novel',
              runtimeBaselineId: 'continuous_autonomous',
            );
        final bundle = documentService.buildBundle(
          projectId: 'demo_project',
          manifest: manifest,
          runtimeProfile: runtimeProfile,
          characters: const <CharacterProfile>[
            CharacterProfile(id: 'hero_01', displayName: '主角'),
          ],
          styles: const <StyleProfile>[
            StyleProfile(
              id: 'serial_style',
              displayName: '连载风格',
              summary: '偏悬疑。',
            ),
          ],
          promptTemplates: const <JsonMap>[
            <String, Object?>{
              'id': 'chapter_atomic_plus',
              'name': '章节任务增强模板',
              'scope': 'task',
              'content': '请结合 {{chapter}} 完成任务。',
            },
          ],
          createdAt: '2026-05-25T12:30:00Z',
        );

        expect(bundle['kind'], BundleKind.projectPackage);
        expect(
          (bundle['project'] as Map<String, Object?>)['project_id'],
          'demo_project',
        );
        expect(bundle['project_manifest'], isNotNull);
        expect(bundle['runtime_profile'], isNotNull);
        expect((bundle['characters'] as List<Object?>), hasLength(1));
        expect((bundle['prompt_templates'] as List<Object?>), hasLength(1));
        final validation = validationService.validateBundle(
          bundle,
          expectedKind: BundleKind.projectPackage,
        );
        expect(validation.ok, isTrue);
      },
    );

    test(
      'project package preview reports project id conflict and entry conflicts',
      () {
        final documentService = ProjectPackageDocumentService();
        final previewService = ProjectPackageImportPreviewService();
        final bundleContent = documentService.encodeBundle(
          documentService.buildBundle(
            projectId: 'project_alpha',
            manifest: const ProjectManifest(
              title: '甲项目',
              projectType: 'standard_novel',
            ),
            runtimeProfile: const ProjectRuntimeProfile(
              projectType: 'standard_novel',
              runtimeBaselineId: '',
              runtimeMode: 'single_chapter_atomic',
              initialRunOptions: <String, Object?>{},
            ),
            characters: const <CharacterProfile>[
              CharacterProfile(id: 'hero_01', displayName: '主角'),
            ],
            styles: const <StyleProfile>[
              StyleProfile(
                id: 'serial_style',
                displayName: '连载风格',
                summary: '偏冷静。',
              ),
            ],
            promptTemplates: const <JsonMap>[
              <String, Object?>{
                'id': 'chapter_atomic_plus',
                'name': '章节任务增强模板',
                'scope': 'task',
                'content': '请结合 {{chapter}} 完成任务。',
              },
            ],
            createdAt: '2026-05-25T12:40:00Z',
          ),
        );

        final preview = previewService.previewBundle(
          bundleContent: bundleContent,
          existingProjectId: 'project_beta',
          existingCharacters: const <JsonMap>[
            <String, Object?>{'id': 'hero_01', 'display_name': '旧主角'},
          ],
          existingOrganizations: const <JsonMap>[],
          existingStyles: const <JsonMap>[
            <String, Object?>{'id': 'serial_style', 'display_name': '旧风格'},
          ],
          existingTemplates: const <JsonMap>[
            <String, Object?>{'id': 'chapter_atomic_plus', 'name': '旧模板'},
          ],
        );

        expect(preview.totalCount, 4);
        expect(preview.conflictCount, 4);
        expect(preview.items.first.entryKind, 'project');
        expect(preview.items.first.status, 'project_conflict');
      },
    );
  });
}
