import 'dart:io';

import 'desktop_app_paths.dart';

class DesktopAppPathsProvider {
  DesktopAppPathsProvider({Map<String, String>? environment})
    : _environment = environment ?? Platform.environment;

  final Map<String, String> _environment;

  DesktopAppPaths resolve({String? workingDirectoryPath}) {
    // 中文注释: 桌面端路径提供器统一决定设置目录和默认项目目录，避免宿主再回退到当前目录。
    final homePath = _resolveHomePath();
    final documentsPath = _resolveDocumentsPath(homePath);
    final settingsRootPath = _normalizePath(
      _firstNonEmpty(<String>[
        _env('NOVEL_AGENT_SETTINGS_ROOT'),
        if (Platform.isWindows) _join(_env('APPDATA'), 'NovelAgent'),
        if (Platform.isMacOS)
          _join(homePath, 'Library', 'Application Support', 'NovelAgent'),
        if (Platform.isLinux)
          _join(
            _env('XDG_CONFIG_HOME').isEmpty
                ? _join(homePath, '.config')
                : _env('XDG_CONFIG_HOME'),
            'NovelAgent',
          ),
      ]),
    );
    final defaultProjectRootPath = _normalizePath(
      _firstNonEmpty(<String>[
        _env('NOVEL_AGENT_DEFAULT_PROJECT_ROOT'),
        _join(documentsPath, 'NovelAgent', 'default_project'),
        _join(homePath, 'NovelAgent', 'default_project'),
      ]),
    );
    final settingsSearchRoots = <String>[
      settingsRootPath,
      if (workingDirectoryPath != null &&
          workingDirectoryPath.trim().isNotEmpty)
        Directory(workingDirectoryPath).absolute.path,
    ];
    return DesktopAppPaths(
      settingsRootPath: settingsRootPath,
      defaultProjectRootPath: defaultProjectRootPath,
      settingsSearchRoots: settingsSearchRoots,
    );
  }

  String _resolveHomePath() {
    // 中文注释: 家目录解析集中在这里，方便 Windows、macOS、Linux 共用一套兜底逻辑。
    return _normalizePath(
      _firstNonEmpty(<String>[
        _env('HOME'),
        _env('USERPROFILE'),
        _join(_env('HOMEDRIVE'), _env('HOMEPATH')),
        Directory.systemTemp.parent.path,
      ]),
    );
  }

  String _resolveDocumentsPath(String homePath) {
    // 中文注释: 默认项目尽量落在用户文档目录，找不到时再退回家目录，保持桌面端可见且可管理。
    return _normalizePath(
      _firstNonEmpty(<String>[
        _env('NOVEL_AGENT_DOCUMENTS_ROOT'),
        _env('DOCUMENTS'),
        _join(homePath, 'Documents'),
        homePath,
      ]),
    );
  }

  String _env(String key) {
    // 中文注释: 环境变量读取收口到一处，方便后续扩展大小写兼容。
    return (_environment[key] ?? '').trim();
  }

  String _firstNonEmpty(List<String> values) {
    // 中文注释: 多来源兜底选择逻辑统一处理，避免每个路径字段都手写相同判断。
    for (final value in values) {
      if (value.trim().isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _join(String left, String right, [String? third, String? fourth]) {
    // 中文注释: 轻量路径拼接放在提供器内部即可，避免为少量路径规则引入额外依赖。
    final segments = <String>[
      left,
      right,
      if (third != null) third,
      if (fourth != null) fourth,
    ].where((segment) => segment.trim().isNotEmpty).toList(growable: false);
    if (segments.isEmpty) {
      return '';
    }
    return segments.join(Platform.pathSeparator);
  }

  String _normalizePath(String path) {
    // 中文注释: 统一转成绝对路径，减少后续设置仓储和项目仓储对相对路径的猜测。
    if (path.trim().isEmpty) {
      return Directory.systemTemp.path;
    }
    return Directory(path).absolute.path;
  }
}
