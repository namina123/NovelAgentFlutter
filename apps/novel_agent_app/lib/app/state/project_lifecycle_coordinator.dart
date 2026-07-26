import 'package:novel_agent_core/novel_agent_core.dart';

import '../../features/workbench/presentation/models/project_launcher_view_data.dart';

enum ProjectLifecycleResolutionKind {
  opened,
  missingSettings,
  missingDefaultProjectPath,
  invalidDefaultProjectPath,
  invalidProjectPath,
}

class ProjectLifecycleResolution {
  const ProjectLifecycleResolution({
    required this.kind,
    required this.statusMessage,
    this.projectPath = '',
    this.shouldShowLauncher = false,
    this.launcherMode,
    this.launcherStatus = '',
    this.canDismiss = false,
  });

  final ProjectLifecycleResolutionKind kind;
  final String statusMessage;
  final String projectPath;
  final bool shouldShowLauncher;
  final ProjectLauncherMode? launcherMode;
  final String launcherStatus;
  final bool canDismiss;

  bool get isLoaded => kind == ProjectLifecycleResolutionKind.opened;
}

class ProjectLifecycleCoordinator {
  ProjectLifecycleCoordinator({
    required AppSettings? Function() readSettings,
    required Future<bool> Function(
      String rootPath, {
      bool deferHydration,
      bool openDefaultDocument,
    })
    loadProject,
    required ProjectDescriptor? Function() readCurrentProject,
    required bool Function() isMobileProjectRootLocked,
  }) : _readSettings = readSettings,
       _loadProject = loadProject,
       _readCurrentProject = readCurrentProject,
       _isMobileProjectRootLocked = isMobileProjectRootLocked;

  final AppSettings? Function() _readSettings;
  final Future<bool> Function(
    String rootPath, {
    bool deferHydration,
    bool openDefaultDocument,
  })
  _loadProject;
  final ProjectDescriptor? Function() _readCurrentProject;
  final bool Function() _isMobileProjectRootLocked;

  Future<ProjectLifecycleResolution> loadDefaultProject() async {
    // 中文注释: 默认项目恢复的判定统一在这里做，调用方只消费结果和投影提示，不再各自写一遍分支。
    final settings = _readSettings();
    if (settings == null) {
      return const ProjectLifecycleResolution(
        kind: ProjectLifecycleResolutionKind.missingSettings,
        statusMessage: '请先创建项目，或在桌面端打开一个已有项目。',
        shouldShowLauncher: true,
        launcherMode: ProjectLauncherMode.create,
        launcherStatus: '当前还没有可恢复的有效项目。先创建一部新作品，或打开已有项目。',
      );
    }
    final defaultPath = settings.defaultProjectPath.trim();
    if (defaultPath.isEmpty) {
      return const ProjectLifecycleResolution(
        kind: ProjectLifecycleResolutionKind.missingDefaultProjectPath,
        statusMessage: '请先创建项目，或在桌面端打开一个已有项目。',
        shouldShowLauncher: true,
        launcherMode: ProjectLauncherMode.create,
        launcherStatus: '当前还没有有效项目。先创建一部新作品，或打开已有项目。',
      );
    }
    final loadAttempt = await _tryLoadProject(
      defaultPath,
      deferHydration: true,
      openDefaultDocument: false,
    );
    if (!loadAttempt.isLoaded) {
      final failureMessage = loadAttempt.failureMessage ??
          '上次打开的项目不可用：$defaultPath。请创建新作品，或重新打开已有项目。';
      return ProjectLifecycleResolution(
        kind: ProjectLifecycleResolutionKind.invalidDefaultProjectPath,
        projectPath: defaultPath,
        statusMessage: failureMessage,
        shouldShowLauncher: true,
        launcherMode: ProjectLauncherMode.create,
        launcherStatus: failureMessage,
      );
    }
    return ProjectLifecycleResolution(
      kind: ProjectLifecycleResolutionKind.opened,
      projectPath: defaultPath,
      statusMessage: '已恢复默认项目：$defaultPath',
    );
  }

  Future<ProjectLifecycleResolution> openProjectFromPath(
    String rootPath, {
    ProjectLauncherMode? failureLauncherMode,
    String? failureLauncherStatus,
  }) async {
    // 中文注释: 显式打开项目的判定统一在这里做，避免入口页、创建页和工作台各写一套打开失败语义。
    final normalizedPath = rootPath.trim();
    if (normalizedPath.isEmpty) {
      return ProjectLifecycleResolution(
        kind: ProjectLifecycleResolutionKind.invalidProjectPath,
        statusMessage: '未识别到有效项目目录。',
        shouldShowLauncher: failureLauncherMode != null,
        launcherMode: failureLauncherMode,
        launcherStatus: failureLauncherStatus ?? '未识别到有效项目目录。',
        canDismiss: _readCurrentProject() != null,
      );
    }
    final loadAttempt = await _tryLoadProject(
      normalizedPath,
      deferHydration: true,
      openDefaultDocument: true,
    );
    if (!loadAttempt.isLoaded) {
      final failureMessage = loadAttempt.failureMessage ??
          failureLauncherStatus ??
          '打开项目失败：$normalizedPath';
      return ProjectLifecycleResolution(
        kind: ProjectLifecycleResolutionKind.invalidProjectPath,
        projectPath: normalizedPath,
        statusMessage: failureMessage,
        shouldShowLauncher: failureLauncherMode != null,
        launcherMode: failureLauncherMode,
        launcherStatus: failureMessage,
        canDismiss: _readCurrentProject() != null,
      );
    }
    return ProjectLifecycleResolution(
      kind: ProjectLifecycleResolutionKind.opened,
      projectPath: normalizedPath,
      statusMessage: '已打开项目：$normalizedPath',
    );
  }

  bool get isMobileProjectRootLocked => _isMobileProjectRootLocked();

  Future<_ProjectLoadAttempt> _tryLoadProject(
    String rootPath, {
    required bool deferHydration,
    required bool openDefaultDocument,
  }) async {
    try {
      final loaded = await _loadProject(
        rootPath,
        deferHydration: deferHydration,
        openDefaultDocument: openDefaultDocument,
      );
      return _ProjectLoadAttempt(isLoaded: loaded);
    } on ProjectManifestCorruptionException catch (_) {
      return _ProjectLoadAttempt(
        isLoaded: false,
        failureMessage:
            '项目清单损坏或包含未知合同字段，系统未改写项目。请从备份恢复 .novel_agent/project_manifest.json 后重试。',
      );
    } catch (_) {
      // A corrupt or unavailable project must return the normal recovery
      // state instead of leaving an entry-point action without feedback.
      return const _ProjectLoadAttempt(isLoaded: false);
    }
  }
}

class _ProjectLoadAttempt {
  const _ProjectLoadAttempt({required this.isLoaded, this.failureMessage});

  final bool isLoaded;
  final String? failureMessage;
}
