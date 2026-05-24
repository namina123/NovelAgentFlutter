import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class PackageRootPathResolver {
  const PackageRootPathResolver({String? workspaceRootPath})
    : _workspaceRootPath = workspaceRootPath;

  final String? _workspaceRootPath;

  List<String> resolveAgentGroupRoots(ProjectDescriptor project) {
    final result = <String>[];
    _appendIfExists(result, _builtinAgentGroupRootPath());
    _appendIfExists(
      result,
      '${project.rootPath}${Platform.pathSeparator}agent_groups',
    );
    return List<String>.unmodifiable(result);
  }

  List<String> resolveAgentRoots(ProjectDescriptor project) {
    // 中文注释: 智能体包与技能包保持同一目录解析策略，只是目标子目录不同。
    final result = <String>[];
    _appendIfExists(result, _builtinAgentRootPath());
    _appendIfExists(
      result,
      '${project.rootPath}${Platform.pathSeparator}agents',
    );
    return List<String>.unmodifiable(result);
  }

  List<String> resolveSkillRoots(ProjectDescriptor project) {
    // 中文注释: 包根路径解析集中在这里，后续改成 assets、用户目录或下载目录时只替换这一层。
    final result = <String>[];
    _appendIfExists(result, _builtinSkillRootPath());
    _appendIfExists(
      result,
      '${project.rootPath}${Platform.pathSeparator}skills',
    );
    return List<String>.unmodifiable(result);
  }

  List<String> resolveSkillGroupRoots(ProjectDescriptor project) {
    final result = <String>[];
    _appendIfExists(result, _builtinSkillGroupRootPath());
    _appendIfExists(
      result,
      '${project.rootPath}${Platform.pathSeparator}skill_groups',
    );
    return List<String>.unmodifiable(result);
  }

  String _builtinSkillRootPath() {
    final workspaceRootPath = (_workspaceRootPath ?? '').trim();
    if (workspaceRootPath.isEmpty) {
      return '';
    }
    return Directory(
      '$workspaceRootPath${Platform.pathSeparator}builtin_packages${Platform.pathSeparator}skills',
    ).absolute.path;
  }

  String _builtinSkillGroupRootPath() {
    final workspaceRootPath = (_workspaceRootPath ?? '').trim();
    if (workspaceRootPath.isEmpty) {
      return '';
    }
    return Directory(
      '$workspaceRootPath${Platform.pathSeparator}builtin_packages${Platform.pathSeparator}skill_groups',
    ).absolute.path;
  }

  String _builtinAgentRootPath() {
    final workspaceRootPath = (_workspaceRootPath ?? '').trim();
    if (workspaceRootPath.isEmpty) {
      return '';
    }
    return Directory(
      '$workspaceRootPath${Platform.pathSeparator}builtin_packages${Platform.pathSeparator}agents',
    ).absolute.path;
  }

  String _builtinAgentGroupRootPath() {
    final workspaceRootPath = (_workspaceRootPath ?? '').trim();
    if (workspaceRootPath.isEmpty) {
      return '';
    }
    return Directory(
      '$workspaceRootPath${Platform.pathSeparator}builtin_packages${Platform.pathSeparator}agent_groups',
    ).absolute.path;
  }

  void _appendIfExists(List<String> result, String path) {
    final cleanPath = path.trim();
    if (cleanPath.isEmpty) {
      return;
    }
    final absolutePath = Directory(cleanPath).absolute.path;
    if (!Directory(absolutePath).existsSync() ||
        result.contains(absolutePath)) {
      return;
    }
    result.add(absolutePath);
  }
}
