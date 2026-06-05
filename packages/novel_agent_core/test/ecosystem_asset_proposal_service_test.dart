import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('EcosystemAssetProposalService', () {
    test(
      'validates and installs non-builtin skill proposal through audited lifecycle',
      () {
        final service = EcosystemAssetProposalService();
        final draft = service.createDraft(
          assetKind: EcosystemAssetKind.skill,
          assetId: 'custom_skill',
          version: '1',
          summary: '项目内技能草案',
          riskNote: '需要人工确认后才能安装。',
          requiredCapabilities: const <String>[
            SkillCapabilityCatalogService.projectRead,
          ],
          assetPayload: <String, Object?>{
            'id': 'custom_skill',
            'name': '项目资料技能',
            'description': '读取项目资料并整理重点。',
            'version': '1',
            'instruction_markdown': '# 项目资料技能\n\n先读取，再整理。',
            'required_capabilities': const <String>[
              SkillCapabilityCatalogService.projectRead,
            ],
          },
        );

        final review = service.review(draft);
        final confirmed = service.confirm(review.proposal);
        final installation = service.install(confirmed);

        expect(draft.proposalStatus, EcosystemAssetLifecycleStatus.proposal);
        expect(review.isValid, isTrue);
        expect(
          review.proposal.proposalStatus,
          EcosystemAssetLifecycleStatus.validated,
        );
        expect(
          confirmed.proposalStatus,
          EcosystemAssetLifecycleStatus.confirmed,
        );
        expect(
          installation.proposal.proposalStatus,
          EcosystemAssetLifecycleStatus.installed,
        );
        expect(installation.relativePath, 'skills/custom_skill/SKILL.md');
        expect(installation.content, contains('id: "custom_skill"'));
      },
    );

    test(
      'covers minimal draft validation for all four ecosystem asset kinds',
      () {
        final service = EcosystemAssetProposalService();
        final reviews = <EcosystemAssetProposalReview>[
          service.review(
            service.createDraft(
              assetKind: EcosystemAssetKind.skill,
              assetId: 'skill_alpha',
              version: '1',
              summary: '技能摘要',
              riskNote: '技能安装前需确认。',
              requiredCapabilities: const <String>[
                SkillCapabilityCatalogService.projectRead,
              ],
              assetPayload: <String, Object?>{
                'id': 'skill_alpha',
                'name': '技能 Alpha',
                'description': '说明',
                'version': '1',
                'instruction_markdown': '正文',
                'required_capabilities': const <String>[
                  SkillCapabilityCatalogService.projectRead,
                ],
              },
            ),
          ),
          service.review(
            service.createDraft(
              assetKind: EcosystemAssetKind.skillGroup,
              assetId: 'skill_group_alpha',
              version: '1',
              summary: '技能组摘要',
              riskNote: '技能组安装前需确认。',
              assetPayload: <String, Object?>{
                'id': 'skill_group_alpha',
                'name': '技能组 Alpha',
                'description': '说明',
                'version': '1',
                'skills': const <String>['skill_alpha'],
              },
            ),
          ),
          service.review(
            service.createDraft(
              assetKind: EcosystemAssetKind.agent,
              assetId: 'agent_alpha',
              version: '1',
              summary: '智能体摘要',
              riskNote: '智能体安装前需确认。',
              requiredCapabilities: const <String>[
                SkillCapabilityCatalogService.projectRead,
              ],
              assetPayload: <String, Object?>{
                'id': 'agent_alpha',
                'name': '智能体 Alpha',
                'description': '说明',
                'version': '1',
                'role': '分析员',
                'objective': '整理项目资料',
                'system_prompt': '先读资料再回答。',
                'required_capabilities': const <String>[
                  SkillCapabilityCatalogService.projectRead,
                ],
              },
            ),
          ),
          service.review(
            service.createDraft(
              assetKind: EcosystemAssetKind.agentGroup,
              assetId: 'agent_group_alpha',
              version: '1',
              summary: '智能体组摘要',
              riskNote: '智能体组安装前需确认。',
              assetPayload: <String, Object?>{
                'id': 'agent_group_alpha',
                'name': '智能体组 Alpha',
                'description': '说明',
                'version': '1',
                'orchestration': 'supervised',
                'agents': const <String>['agent_alpha'],
              },
            ),
          ),
        ];

        for (final review in reviews) {
          expect(review.errors, isEmpty);
          expect(review.proposal.validationErrors, isEmpty);
          expect(
            review.proposal.proposalStatus,
            EcosystemAssetLifecycleStatus.validated,
          );
        }
      },
    );

    test(
      'invalid proposal can stay in proposal state and later be rejected',
      () {
        final service = EcosystemAssetProposalService();
        final review = service.review(
          service.createDraft(
            assetKind: EcosystemAssetKind.agentGroup,
            assetId: 'empty_group',
            version: '1',
            summary: '',
            riskNote: '',
            assetPayload: <String, Object?>{
              'id': 'empty_group',
              'name': '',
              'description': '',
              'version': '',
              'agents': const <String>[],
            },
          ),
        );
        final rejected = service.reject(review.proposal, reason: '缺少最小草案信息。');

        expect(review.isValid, isFalse);
        expect(
          review.proposal.proposalStatus,
          EcosystemAssetLifecycleStatus.proposal,
        );
        expect(rejected.proposalStatus, EcosystemAssetLifecycleStatus.rejected);
        expect(rejected.metadata['rejection_reason'], '缺少最小草案信息。');
      },
    );
  });

  test(
    'customization bundle import writes proposal records instead of installed files',
    () async {
      final hostPort = _FakeProjectToolHostPort();
      final useCase = ImportCustomizationBundleUseCase(
        projectToolHostPort: hostPort,
        generateCustomizationIndexesUseCase:
            GenerateCustomizationIndexesUseCase(
              writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
                projectWorkspacePort: hostPort,
              ),
            ),
      );
      final result = await useCase.execute(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        overwrite: true,
        bundleContent: jsonEncode(<String, Object?>{
          'kind': 'novel_agent_customization_bundle',
          'skills': <Object?>[
            <String, Object?>{
              'id': 'demo-skill',
              'name': '示例技能',
              'description': '导入测试技能。',
              'version': '1',
              'instruction_markdown': '正文',
              'required_capabilities': const <String>[
                SkillCapabilityCatalogService.projectRead,
              ],
            },
          ],
        }),
      );

      final changedPaths = ValueReaders.stringList(result['changed_paths']);
      final proposalPath = changedPaths.single;
      final proposal = EcosystemAssetProposal.fromJson(
        ValueReaders.mapValue(jsonDecode(hostPort.readStored(proposalPath))),
      );

      expect(result['ok'], isTrue);
      expect(
        proposalPath,
        startsWith('.novel_agent/ecosystem/proposals/skill/'),
      );
      expect(proposal.proposalStatus, EcosystemAssetLifecycleStatus.validated);
      expect(hostPort.readStored('skills/demo-skill/SKILL.md'), isEmpty);
    },
  );
}

class _FakeProjectToolHostPort
    implements ProjectToolHostPort, ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};
  final Set<String> _directories = <String>{};

  String readStored(String relativePath) => _files[relativePath] ?? '';

  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {}

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {
    _directories.add(relativePath);
  }

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {
    _files.remove(relativePath);
    _directories.remove(relativePath);
  }

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async {
    return _files.containsKey(relativePath) ||
        _directories.contains(relativePath);
  }

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return _files.keys
        .map(
          (path) => <String, Object?>{
            'relative_path': path,
            'display_name': path.split('/').last,
            'is_dir': false,
          },
        )
        .toList(growable: false);
  }

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {
    final value = _files.remove(sourceRelativePath);
    if (value != null) {
      _files[targetRelativePath] = value;
    }
  }

  @override
  Future<String?> readExternalTextFile(String absolutePath) async {
    return null;
  }

  @override
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {}

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return _files[relativePath];
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    _files[relativePath] = content;
  }
}
