import 'dart:io';

import 'probe_config_support.dart';

final List<RegExp> _secretPatterns = <RegExp>[
  RegExp(r'sk-[A-Za-z0-9]{20,}'),
  RegExp(r'Bearer\s+sk-[A-Za-z0-9]{20,}', caseSensitive: false),
];

final Set<String> _excludedTopLevelNames = <String>{
  '.git',
  '.dart_tool',
  'artifacts',
  'build',
  'dist',
  'local',
  'references',
};

final Set<String> _excludedFileNames = <String>{
  'test_api.txt',
};

final Set<String> _scannableExtensions = <String>{
  '.dart',
  '.md',
  '.txt',
  '.yaml',
  '.yml',
  '.json',
  '.ps1',
  '.sh',
  '.bat',
  '.kts',
};

Future<void> main(List<String> arguments) async {
  // 中文注释: 仓库级扫描器只检查“可能进入提交”的源码与文档，避免再次把明文 key 带进历史。
  final repoRoot = resolveLocalProbeRepoRoot();
  final rootDirectory = Directory(repoRoot);
  final findings = <String>[];
  await for (final entity in rootDirectory.list(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    if (_shouldSkipFile(repoRoot, entity)) {
      continue;
    }
    final content = await _safeReadText(entity);
    if (content == null || content.isEmpty) {
      continue;
    }
    final lines = content.split('\n');
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      for (final pattern in _secretPatterns) {
        if (pattern.hasMatch(line)) {
          findings.add(
            '${_toRepoRelativePath(repoRoot, entity.path)}:${index + 1}: ${line.trim()}',
          );
          break;
        }
      }
    }
  }
  if (findings.isEmpty) {
    stdout.writeln('repository_secret_scan: PASS');
    return;
  }
  stderr.writeln('repository_secret_scan: FAIL');
  for (final finding in findings) {
    stderr.writeln(finding);
  }
  exitCode = 1;
}

bool _shouldSkipFile(String repoRoot, File file) {
  // 中文注释: 这里排除本地敏感目录、构建产物和显然不应进入仓库扫描面的文件，专注检查正式代码与文档面。
  final relativePath = _toRepoRelativePath(repoRoot, file.path);
  if (relativePath.isEmpty) {
    return true;
  }
  final segments = relativePath.split('/');
  if (segments.isEmpty) {
    return true;
  }
  if (_excludedTopLevelNames.contains(segments.first)) {
    return true;
  }
  if (_excludedFileNames.contains(segments.last)) {
    return true;
  }
  if (segments.contains('generated')) {
    return true;
  }
  final lowerPath = relativePath.toLowerCase();
  if (lowerPath.endsWith('.png') ||
      lowerPath.endsWith('.jpg') ||
      lowerPath.endsWith('.jpeg') ||
      lowerPath.endsWith('.gif') ||
      lowerPath.endsWith('.pdf') ||
      lowerPath.endsWith('.sqlite3') ||
      lowerPath.endsWith('.zip')) {
    return true;
  }
  final extensionIndex = lowerPath.lastIndexOf('.');
  if (extensionIndex < 0) {
    return false;
  }
  return !_scannableExtensions.contains(lowerPath.substring(extensionIndex));
}

Future<String?> _safeReadText(File file) async {
  // 中文注释: 个别二进制或编码异常文件不值得中断扫描，直接跳过即可。
  try {
    return await file.readAsString();
  } catch (_) {
    return null;
  }
}

String _toRepoRelativePath(String repoRoot, String absolutePath) {
  final normalizedRoot = repoRoot.replaceAll('\\', '/');
  final normalizedPath = absolutePath.replaceAll('\\', '/');
  if (!normalizedPath.startsWith(normalizedRoot)) {
    return normalizedPath;
  }
  return normalizedPath
      .substring(normalizedRoot.length)
      .replaceFirst(RegExp(r'^/+'), '');
}
