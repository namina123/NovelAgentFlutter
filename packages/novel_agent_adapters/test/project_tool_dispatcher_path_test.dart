import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectToolDispatcher path ingress', () {
    test(
      'resolves Chinese workspace label only at dispatcher boundary',
      () async {
        // 中文注释: 这里验证中文目录标签只在工具入口归一化一次，执行器收到的仍是英文相对路径。
        final hostPort = _FakeProjectToolHostPort(
          files: <String, String>{'chapter_outlines/ch1.md': '# 第一章'},
        );
        final dispatcher = ProjectToolDispatcher(hostPort: hostPort);
        final result = await dispatcher.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          toolCall: const <String, Object?>{
            'name': 'read_project_file',
            'arguments': <String, Object?>{'relative_path': '章纲/ch1.md'},
          },
        );
        expect(result['ok'], isTrue);
        expect(result['relative_path'], 'chapter_outlines/ch1.md');
        expect(result['content'], contains('第一章'));
      },
    );

    test(
      'read_project_file without relative_path returns recoverable guidance with english entries preview',
      () async {
        // 中文注释: 缺少路径时应返回可自纠正结果，提示先列目录而不是把整轮工具调用直接打成硬失败。
        final hostPort = _FakeProjectToolHostPort(
          files: <String, String>{'outline/main.md': '# 总纲'},
        );
        final dispatcher = ProjectToolDispatcher(hostPort: hostPort);
        final result = await dispatcher.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          toolCall: const <String, Object?>{
            'name': 'read_project_file',
            'arguments': <String, Object?>{},
          },
        );
        expect(result['ok'], isFalse);
        expect(result['not_executed'], isTrue);
        expect(result['error'], contains('list_project_files'));
        expect(result['entries_preview'], contains('outline/main.md'));
      },
    );

    test(
      'read_project_file accepts path alias at dispatcher boundary',
      () async {
        // 中文注释: 模型若输出 path 而不是 relative_path，入口层也应能兼容，减少无意义的自纠错回合。
        final hostPort = _FakeProjectToolHostPort(
          files: <String, String>{'outline/main.md': '# 总纲'},
        );
        final dispatcher = ProjectToolDispatcher(hostPort: hostPort);
        final result = await dispatcher.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          toolCall: const <String, Object?>{
            'name': 'read_project_file',
            'arguments': <String, Object?>{'path': 'outline/main.md'},
          },
        );
        expect(result['ok'], isTrue);
        expect(result['content'], contains('总纲'));
      },
    );

    test(
      'read_project_file supports line window and hides line numbers on demand',
      () async {
        // 中文注释: 局部读取要能返回稳定行窗，便于后续按行修订，不要求模型每次整篇回读。
        final hostPort = _FakeProjectToolHostPort(
          files: <String, String>{'drafts/source.md': 'A\nB\nC\nD\n'},
        );
        final dispatcher = ProjectToolDispatcher(hostPort: hostPort);
        final result = await dispatcher.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          toolCall: const <String, Object?>{
            'name': 'read_project_file',
            'arguments': <String, Object?>{
              'relative_path': 'drafts/source.md',
              'start_line': 2,
              'limit': 2,
              'exclude_line_numbers': true,
            },
          },
        );
        expect(result['ok'], isTrue);
        expect(result['content'], 'B\nC');
        expect(ValueReaders.intValue(result['selected_start_line']), 2);
        expect(ValueReaders.intValue(result['selected_end_line']), 3);
      },
    );

    test(
      'present_user_options accepts choices alias and normalizes title to label',
      () async {
        // 中文注释: 模型把选项数组写成 choices/items 时，入口层也应能兼容，避免按钮区被吞成空列表。
        final hostPort = _FakeProjectToolHostPort(
          files: const <String, String>{},
        );
        final dispatcher = ProjectToolDispatcher(hostPort: hostPort);
        final result = await dispatcher.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          toolCall: const <String, Object?>{
            'name': 'present_user_options',
            'arguments': <String, Object?>{
              'question': '先选一个方向',
              'choices': <Object?>[
                <String, Object?>{
                  'id': 'opening_a',
                  'title': '稳妥开局',
                  'description': '先把世界观和主角状态铺稳。',
                },
              ],
            },
          },
        );
        expect(result['ok'], isTrue);
        final options = ValueReaders.objectList(
          result['options'],
        ).map(ValueReaders.mapValue).toList(growable: false);
        expect(options, hasLength(1));
        expect(options.first['label'], '稳妥开局');
        expect(options.first['prompt'], '稳妥开局');
      },
    );

    test(
      'run_continuity_check returns markdown and json sibling paths',
      () async {
        // 中文注释: 连续性检查报告应同时落 markdown 与 json，且 json 路径必须保留正确扩展名。
        final hostPort = _FakeProjectToolHostPort(
          files: const <String, String>{},
        );
        final dispatcher = ProjectToolDispatcher(hostPort: hostPort);
        final result = await dispatcher.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          toolCall: const <String, Object?>{
            'name': 'run_continuity_check',
            'arguments': <String, Object?>{
              'title': '测试报告',
              'summary': '整体一致。',
              'issues': <Object?>[],
              'suggestions': <Object?>[],
            },
          },
        );
        expect(result['ok'], isTrue);
        expect(
          ValueReaders.stringValue(result['markdown_path']),
          endsWith('.md'),
        );
        expect(
          ValueReaders.stringValue(result['json_path']),
          endsWith('.json'),
        );
      },
    );

    test('edit_project_file supports regex replacement', () async {
      // 中文注释: 正则替换能减少大段 old_text 精确匹配失败的脆弱性。
      final hostPort = _FakeProjectToolHostPort(
        files: <String, String>{'drafts/source.md': 'Alpha 01\nAlpha 02\n'},
      );
      final dispatcher = ProjectToolDispatcher(hostPort: hostPort);
      final result = await dispatcher.execute(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        toolCall: const <String, Object?>{
          'name': 'edit_project_file',
          'arguments': <String, Object?>{
            'relative_path': 'drafts/source.md',
            'operation': 'replace',
            'pattern': r'Alpha \d+',
            'content': 'Beta',
            'use_regex': true,
          },
        },
      );
      expect(result['ok'], isTrue);
      expect(hostPort.fileContent('drafts/source.md'), 'Beta\nBeta\n');
    });

    test('edit_project_file supports anchored range replacement', () async {
      // 中文注释: 锚点范围替换要能只换中间内容，保留前后边界不动。
      final hostPort = _FakeProjectToolHostPort(
        files: <String, String>{'drafts/source.md': 'BEGIN\nold body\nEND\n'},
      );
      final dispatcher = ProjectToolDispatcher(hostPort: hostPort);
      final result = await dispatcher.execute(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        toolCall: const <String, Object?>{
          'name': 'edit_project_file',
          'arguments': <String, Object?>{
            'relative_path': 'drafts/source.md',
            'operation': 'replace',
            'start_text': 'BEGIN\n',
            'end_text': '\nEND',
            'content': 'new body',
          },
        },
      );
      expect(result['ok'], isTrue);
      expect(
        hostPort.fileContent('drafts/source.md'),
        'BEGIN\nnew body\nEND\n',
      );
    });

    test(
      'manipulate_project_file_lines supports negative source lines',
      () async {
        // 中文注释: 负数行号要能从文件尾部回数，方便快速抽取结尾段落。
        final hostPort = _FakeProjectToolHostPort(
          files: <String, String>{
            'drafts/source.md': 'A\nB\nC\nD\n',
            'drafts/target.md': 'HEAD\n',
          },
        );
        final dispatcher = ProjectToolDispatcher(hostPort: hostPort);
        final result = await dispatcher.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          toolCall: const <String, Object?>{
            'name': 'manipulate_project_file_lines',
            'arguments': <String, Object?>{
              'sourceRelativePath': 'drafts/source.md',
              'target_relative_path': 'drafts/target.md',
              'operation': 'copy',
              'start_line': -2,
              'end_line': -1,
            },
          },
        );
        expect(result['ok'], isTrue);
        expect(hostPort.fileContent('drafts/target.md'), 'HEAD\nD\n');
      },
    );
  });
}

class _FakeProjectToolHostPort implements ProjectToolHostPort {
  _FakeProjectToolHostPort({required Map<String, String> files})
    : _files = Map<String, String>.from(files);

  final Map<String, String> _files;

  String fileContent(String relativePath) => _files[relativePath] ?? '';

  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {}

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {
    _files.remove(relativePath);
  }

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async {
    return _files.containsKey(relativePath);
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
    final content = _files.remove(sourceRelativePath);
    if (content != null) {
      _files[targetRelativePath] = content;
    }
  }

  @override
  Future<String?> readExternalTextFile(String absolutePath) async {
    return null;
  }

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
