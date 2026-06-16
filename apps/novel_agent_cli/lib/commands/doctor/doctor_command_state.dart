part of 'doctor_command.dart';

Future<int> _runDoctorCheck(DoctorCommand command) async {
  // 中文注释: doctor 检查只做只读诊断和临时写权限验证，不在 CLI 里自动修复设置。
  final settings = await command._settingsRepository.load();
  final report = <String, Object?>{
    'platform': _platformLabel(),
    'working_directory': Directory.current.path,
    'default_project_path': settings.defaultProjectPath,
    'default_project_exists': await Directory(settings.defaultProjectPath).exists(),
    'default_project_openable':
        await _projectOpenable(command, settings.defaultProjectPath),
    'provider_count': settings.providers.length,
    'default_provider_id': settings.defaultProviderId,
    'default_provider_present': settings.defaultProvider() != null,
    'temp_write_ok': await _canWriteTempFile(),
    'capabilities': <String, Object?>{
      'stdout_terminal': stdout.hasTerminal,
      'stderr_terminal': stderr.hasTerminal,
      'stdin_terminal': stdin.hasTerminal,
      'desktop_shell': Platform.isWindows || Platform.isLinux || Platform.isMacOS,
    },
    'provider_checks': _providerChecks(settings),
  };
  final issues = _doctorIssues(report);
  command._printer.block('doctor report', _prettyJson(report));
  if (issues.isEmpty) {
    command._printer.success('doctor 检查通过。');
    return 0;
  }
  command._printer.error('doctor 发现问题：${issues.join('；')}');
  return CliExitCodes.configError;
}

String _platformLabel() {
  // 中文注释: 平台信息只做诊断展示，不参与任何运行时分支决策。
  if (Platform.isWindows) {
    return 'windows';
  }
  if (Platform.isLinux) {
    return 'linux';
  }
  if (Platform.isMacOS) {
    return 'macos';
  }
  if (Platform.isAndroid) {
    return 'android';
  }
  if (Platform.isIOS) {
    return 'ios';
  }
  return 'unknown';
}

Future<bool> _canWriteTempFile() async {
  // 中文注释: 临时文件写入用于验证 CLI 运行环境至少具备基础写权限。
  final tempDir = await Directory.systemTemp.createTemp('novel_agent_doctor_');
  final file = File('${tempDir.path}${Platform.pathSeparator}write_check.txt');
  try {
    await file.writeAsString('ok');
    return await file.exists();
  } finally {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

List<JsonMap> _providerChecks(AppSettings settings) {
  // 中文注释: provider 诊断只投影缺失项，不输出 api key 明文。
  final checks = <JsonMap>[];
  for (final provider in settings.providers) {
    final issues = <String>[];
    if (provider.baseUrl.trim().isEmpty) {
      issues.add('missing_base_url');
    }
    if (provider.modelId.trim().isEmpty) {
      issues.add('missing_model_id');
    }
    if (provider.apiKey.trim().isEmpty) {
      issues.add('missing_api_key');
    }
    checks.add(<String, Object?>{
      'id': provider.id,
      'title': provider.title,
      'is_default': provider.isDefault,
      'issues': issues,
    });
  }
  return checks;
}

List<String> _doctorIssues(JsonMap report) {
  // 中文注释: 诊断结论只依赖 report 中的稳定字段，便于 JSON/text 两种输出共用同一判定。
  final issues = <String>[];
  if (!ValueReaders.boolValue(report['default_project_exists'])) {
    issues.add('default_project_missing');
  }
  if (!ValueReaders.boolValue(report['default_project_openable'])) {
    issues.add('default_project_unopenable');
  }
  if (!ValueReaders.boolValue(report['default_provider_present'])) {
    issues.add('default_provider_missing');
  }
  if (!ValueReaders.boolValue(report['temp_write_ok'])) {
    issues.add('temp_write_failed');
  }
  for (final rawCheck in ValueReaders.objectList(report['provider_checks'])) {
    final check = ValueReaders.mapValue(rawCheck);
    final providerIssues = ValueReaders.stringList(check['issues']);
    if (providerIssues.isNotEmpty) {
      issues.add(
        '${ValueReaders.stringValue(check["id"])}:${providerIssues.join(",")}',
      );
    }
  }
  return issues;
}

Future<bool> _projectOpenable(DoctorCommand command, String projectPath) async {
  // 中文注释: 默认项目路径检查直接复用仓储打开能力，避免 doctor 自己猜磁盘状态。
  return (await command._projectRepository.openByPath(projectPath)) != null;
}
