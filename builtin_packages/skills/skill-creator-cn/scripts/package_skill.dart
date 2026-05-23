import 'dart:io';

import 'quick_validate.dart';

Future<void> main(List<String> args) async {
  // 中文注释: 该脚本先验证技能，再调用宿主可用的压缩能力打包 zip，保持分发流程稳定。
  if (args.isEmpty || args.length > 2) {
    stdout.writeln('用法：dart package_skill.dart <技能目录> [输出目录]');
    exit(1);
  }
  final skillDirectory = Directory(args.first).absolute;
  if (!await skillDirectory.exists()) {
    stderr.writeln('未找到技能目录：${skillDirectory.path}');
    exit(1);
  }
  final validation = validateSkillDirectory(skillDirectory.path);
  if (!validation.ok) {
    stderr.writeln('验证失败：${validation.message}');
    exit(1);
  }
  final outputDirectory = Directory(
    args.length == 2 ? args[1] : Directory.current.path,
  ).absolute;
  await outputDirectory.create(recursive: true);
  final zipPath = '${outputDirectory.path}${Platform.pathSeparator}${skillDirectory.uri.pathSegments.where((part) => part.trim().isNotEmpty).last}.zip';
  final exitCode = await _packageDirectory(skillDirectory.path, zipPath);
  if (exitCode != 0) {
    stderr.writeln('打包失败，请检查宿主压缩能力是否可用。');
    exit(exitCode);
  }
  stdout.writeln('已成功打包技能到：$zipPath');
}

Future<int> _packageDirectory(String sourcePath, String zipPath) async {
  // 中文注释: 这里优先用当前平台现成压缩能力，避免为一个简单分发脚本引入重依赖。
  if (Platform.isWindows) {
    final process = await Process.start(
      'powershell',
      <String>[
        '-NoProfile',
        '-Command',
        "Compress-Archive -Path '${sourcePath}\\*' -DestinationPath '$zipPath' -Force",
      ],
      runInShell: true,
    );
    stdout.write(await process.stdout.transform(SystemEncoding().decoder).join());
    stderr.write(await process.stderr.transform(SystemEncoding().decoder).join());
    return process.exitCode;
  }
  final process = await Process.start(
    'zip',
    <String>['-r', zipPath, '.'],
    workingDirectory: sourcePath,
    runInShell: true,
  );
  stdout.write(await process.stdout.transform(SystemEncoding().decoder).join());
  stderr.write(await process.stderr.transform(SystemEncoding().decoder).join());
  return process.exitCode;
}
