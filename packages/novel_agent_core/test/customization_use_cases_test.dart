import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Customization services', () {
    test('skill markdown renderer preserves id and name after round trip', () {
      // 中文注释: 这里验证技能包渲染后再解析，不会把显示名误丢成目录 id。
      final renderer = SkillMarkdownPackageRendererService();
      final parser = SkillMarkdownPackageParserService();

      final markdown = renderer.renderPackage(<String, Object?>{
        'id': 'outline-maker',
        'name': '大纲师',
        'description': '用于整理总纲和章纲。',
        'instruction_markdown': '# 大纲师\n\n先整理结构，再补充细节。',
      });
      final parsed = parser.parsePackage(markdown, fallbackId: 'outline-maker');

      expect(parsed['id'], 'outline-maker');
      expect(parsed['name'], '大纲师');
    });

    test(
      'preview customization bundle import reports project and builtin conflicts',
      () {
        // 中文注释: 这里验证预检结果会区分项目冲突和内置遮蔽，供 GUI/CLI 在导入前统一提示。
        final useCase = PreviewCustomizationBundleImportUseCase();
        final preview = useCase.execute(
          bundleContent: jsonEncode(<String, Object?>{
            'kind': 'novel_agent_customization_bundle',
            'title': '测试生态包',
            'skills': <Object?>[
              <String, Object?>{'id': 'project-skill', 'name': '项目技能'},
            ],
            'agents': <Object?>[
              <String, Object?>{'id': 'builtin-agent', 'name': '内置智能体覆盖'},
            ],
          }),
          overwrite: false,
          allowBuiltinShadow: false,
          projectSkills: const <JsonMap>[
            <String, Object?>{'id': 'project-skill', 'name': '已有项目技能'},
          ],
          builtinAgents: const <JsonMap>[
            <String, Object?>{'id': 'builtin-agent', 'name': '内置智能体'},
          ],
        );

        expect(preview['ok'], true);
        final items = ValueReaders.objectList(
          preview['items'],
        ).map(ValueReaders.mapValue).toList(growable: false);
        expect(items, hasLength(2));
        expect(items.first['status'], 'project_conflict');
        expect(items.first['action'], 'skip');
        expect(items.last['status'], 'builtin_override');
        expect(items.last['action'], 'skip_builtin');
      },
    );

    test('market index document service summarizes exported bundles', () {
      // 中文注释: 这里验证市场索引只保留摘要字段，且能正确统计四类生态条目数量。
      final service = CustomizationMarketIndexDocumentService();
      final index = service.buildLocalIndex(const <JsonMap>[
        <String, Object?>{
          'relative_path': 'exports/demo.customization.json',
          'title': '演示包',
          'description': '一个简单测试包。',
          'agents': <Object?>[
            <String, Object?>{'id': 'a'},
          ],
          'skills': <Object?>[
            <String, Object?>{'id': 's1'},
            <String, Object?>{'id': 's2'},
          ],
          'skill_groups': <Object?>[
            <String, Object?>{'id': 'sg'},
          ],
          'agent_groups': const <Object?>[],
        },
      ]);

      final entries = ValueReaders.objectList(
        index['entries'],
      ).map(ValueReaders.mapValue).toList(growable: false);
      expect(entries, hasLength(1));
      expect(entries.first['agent_count'], 1);
      expect(entries.first['skill_count'], 2);
      expect(entries.first['skill_group_count'], 1);
      expect(entries.first['agent_group_count'], 0);
    });

    test(
      'project asset bundle preview distinguishes new and conflicting assets',
      () {
        // 中文注释: 资产包预检要能给 GUI/CLI 一致的冲突判断，不把风格和伏笔混成笼统导入结果。
        final useCase = PreviewProjectAssetBundleImportUseCase();
        final preview = useCase.execute(
          bundleContent: jsonEncode(<String, Object?>{
            'kind': 'novel_agent_project_asset_bundle',
            'title': '资产包',
            'styles': <Object?>[
              <String, Object?>{'id': 'serial-style', 'display_name': '连载风格'},
            ],
            'foreshadows': <Object?>[
              <String, Object?>{'id': 'tower-secret', 'title': '高塔秘密'},
            ],
          }),
          overwrite: false,
          projectStyles: const <JsonMap>[
            <String, Object?>{'id': 'serial-style'},
          ],
        );
        expect(preview['ok'], isTrue);
        final items = ValueReaders.objectList(
          preview['items'],
        ).map(ValueReaders.mapValue).toList(growable: false);
        expect(items, hasLength(2));
        expect(items.first['status'], 'project_conflict');
        expect(items.first['action'], 'skip');
        expect(items.last['status'], 'new');
        expect(items.last['action'], 'import');
      },
    );

    test(
      'project asset bundle import writes style and foreshadow files',
      () async {
        // 中文注释: 导入落盘必须统一生成标准资产路径，后续 GUI/CLI 才能共享浏览、索引和上下文装配。
        final hostPort = _FakeProjectToolHostPort();
        final useCase = ImportProjectAssetBundleUseCase(
          projectToolHostPort: hostPort,
        );
        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          overwrite: false,
          bundleContent: jsonEncode(<String, Object?>{
            'kind': 'novel_agent_project_asset_bundle',
            'title': '资产包',
            'styles': <Object?>[
              <String, Object?>{
                'id': 'serial-style',
                'display_name': '连载风格',
                'summary': '偏克制、偏悬疑、偏角色驱动。',
              },
            ],
            'foreshadows': <Object?>[
              <String, Object?>{
                'id': 'tower-secret',
                'title': '高塔秘密',
                'summary': '第一卷埋下高塔异常。',
                'notes': '第三卷回收。',
              },
            ],
          }),
        );

        expect(result['ok'], isTrue);
        expect(ValueReaders.stringList(result['changed_paths']), hasLength(2));
        expect(
          hostPort.readStored('assets/styles/serial-style.style.md'),
          allOf(contains('display_name:'), contains('连载风格')),
        );
        expect(
          hostPort.readStored('assets/foreshadows/tower-secret.foreshadow.md'),
          contains('## 备注'),
        );
      },
    );

    test(
      'project asset bundle import prepares structured assets before projections',
      () async {
        final events = <String>[];
        final hostPort = _FakeProjectToolHostPort(
          onWrite: (relativePath) => events.add('projection:$relativePath'),
        );
        final useCase = ImportProjectAssetBundleUseCase(
          projectToolHostPort: hostPort,
        );

        await useCase.execute(
          project: const ProjectDescriptor(
            id: 'sqlite-demo',
            name: 'SQLite 资产项目',
            rootPath: 'D:/sqlite-demo',
            storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          ),
          bundleContent: jsonEncode(<String, Object?>{
            'kind': 'novel_agent_project_asset_bundle',
            'title': '资产包',
            'styles': <Object?>[
              <String, Object?>{'id': 'serial-style', 'display_name': '连载风格'},
            ],
            'foreshadows': <Object?>[
              <String, Object?>{'id': 'tower-secret', 'title': '高塔秘密'},
            ],
          }),
          prepareDocumentWrite:
              ({
                required project,
                required relativePath,
                required documentKind,
                required title,
                required content,
              }) async {
                events.add('primary:$documentKind:$relativePath:$title');
              },
        );

        expect(events, <String>[
          'primary:style:assets/styles/serial-style.style.md:连载风格',
          'projection:assets/styles/serial-style.style.md',
          'primary:foreshadow_record:assets/foreshadows/tower-secret.foreshadow.md:高塔秘密',
          'projection:assets/foreshadows/tower-secret.foreshadow.md',
        ]);
      },
    );
  });
}

class _FakeProjectToolHostPort implements ProjectToolHostPort {
  _FakeProjectToolHostPort({this.onWrite});

  final void Function(String relativePath)? onWrite;
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
    onWrite?.call(relativePath);
  }
}
