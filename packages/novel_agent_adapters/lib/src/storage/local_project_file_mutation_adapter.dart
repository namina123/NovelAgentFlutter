import 'dart:io';

import 'project_relative_path_resolver.dart';

class LocalProjectFileMutationAdapter {
  LocalProjectFileMutationAdapter({ProjectRelativePathResolver? pathResolver})
    : _pathResolver = pathResolver ?? ProjectRelativePathResolver();

  final ProjectRelativePathResolver _pathResolver;

  Future<bool> entryExists(String rootPath, String relativePath) async {
    // 中文注释: 文件变更适配器专门承接宿主层存在性判断，避免工作区读取端口继续膨胀。
    final resolvedPath = _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: relativePath,
    );
    return await File(resolvedPath).exists() ||
        await Directory(resolvedPath).exists();
  }

  Future<void> createDirectory(String rootPath, String relativePath) async {
    // 中文注释: 目录创建副作用单独收口到变更适配器，保持读工作区和写工作区职责分离。
    final resolvedPath = _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: relativePath,
    );
    await Directory(resolvedPath).create(recursive: true);
  }

  Future<void> deleteEntry(String rootPath, String relativePath) async {
    // 中文注释: 删除逻辑集中在这里处理文件与目录分支，调用方不用再碰 dart:io 细节。
    final resolvedPath = _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: relativePath,
    );
    final file = File(resolvedPath);
    if (await file.exists()) {
      await file.delete();
      return;
    }
    final directory = Directory(resolvedPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {
    // 中文注释: 移动操作由专门适配器负责，便于未来继续细分复制、替换和冲突策略。
    final sourcePath = _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: sourceRelativePath,
    );
    final targetPath = _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: targetRelativePath,
    );
    final sourceFile = File(sourcePath);
    if (await sourceFile.exists()) {
      await Directory(targetPath).parent.create(recursive: true);
      await sourceFile.rename(targetPath);
      return;
    }
    final sourceDirectory = Directory(sourcePath);
    if (await sourceDirectory.exists()) {
      await Directory(targetPath).parent.create(recursive: true);
      await sourceDirectory.rename(targetPath);
    }
  }

  Future<String?> readExternalTextFile(String absolutePath) async {
    // 中文注释: 外部文本读取只承接宿主绝对路径，不参与项目内相对路径规则。
    final file = File(absolutePath);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {
    // 中文注释: 外部文件导入统一落到这里，保证目标仍然经过项目根目录边界检查。
    final sourceFile = File(absolutePath);
    if (!await sourceFile.exists()) {
      throw ArgumentError.value(absolutePath, 'absolutePath', '源文件不存在。');
    }
    final targetPath = _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: targetRelativePath,
    );
    await Directory(targetPath).parent.create(recursive: true);
    await sourceFile.copy(targetPath);
  }
}
