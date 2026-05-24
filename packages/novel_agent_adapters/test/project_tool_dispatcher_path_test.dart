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

    test('read_project_file without relative_path returns english entries preview', () async {
      // 中文注释: 缺少路径时应明确要求复制英文 relative_path，而不是只返回“项目文件”这类空提示。
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
      expect(
        result['error'],
        contains('请先调用 list_project_files'),
      );
      expect(
        result['entries_preview'],
        contains('outline/main.md'),
      );
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
