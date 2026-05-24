import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectToolDispatcher path ingress', () {
    test('resolves Chinese workspace label only at dispatcher boundary', () async {
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
    });

    test('read_project_file without relative_path returns recoverable guidance with english entries preview', () async {
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
      expect(
        result['error'],
        contains('list_project_files'),
      );
      expect(
        result['entries_preview'],
        contains('outline/main.md'),
      );
    });

    test('read_project_file accepts path alias at dispatcher boundary', () async {
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
    });

    test('present_user_options accepts choices alias and normalizes title to label', () async {
      // 中文注释: 模型把选项数组写成 choices/items 时，入口层也应能兼容，避免按钮区被吞成空列表。
      final hostPort = _FakeProjectToolHostPort(files: const <String, String>{});
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
      final options = ValueReaders.objectList(result['options'])
          .map(ValueReaders.mapValue)
          .toList(growable: false);
      expect(options, hasLength(1));
      expect(options.first['label'], '稳妥开局');
      expect(options.first['prompt'], '稳妥开局');
    });
  });
}

class _FakeProjectToolHostPort implements ProjectToolHostPort {
  _FakeProjectToolHostPort({required Map<String, String> files})
    : _files = Map<String, String>.from(files);

  final Map<String, String> _files;

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
