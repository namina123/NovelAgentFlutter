import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

Future<void> main() async {
  // 中文注释: 全工具探针始终在隔离项目副本上运行，避免把验证副作用写进用户正式项目。
  final bundle = AdapterBundle.standard(
    workingDirectoryPath: Directory.current.path,
  );
  final recorder = _ProbeRecorder();
  final sourceProject = await _resolveSourceProject(bundle);
  final probeRoot = await _prepareProbeProject(sourceProject.rootPath);
  final probeProject = await bundle.projectRepository.openByPath(
    probeRoot.path,
  );
  if (probeProject == null) {
    stderr.writeln('无法打开探针项目：${probeRoot.path}');
    exitCode = 2;
    return;
  }

  await _seedProbeFixtures(bundle.projectWorkspacePort, probeProject);
  final httpServer = await _startGatewayProbeServer();
  try {
    await _runProjectToolProbes(
      bundle: bundle,
      project: probeProject,
      recorder: recorder,
      gatewayBaseUrl: 'http://127.0.0.1:${httpServer.port}',
    );
    await _runSubAgentProbe(project: probeProject, recorder: recorder);
  } finally {
    await httpServer.close(force: true);
  }

  final reportPath = await _writeReport(
    probeRoot: probeRoot,
    sourceProject: sourceProject,
    recorder: recorder,
  );
  stdout.writeln('=== Tool Probe Summary ===');
  stdout.writeln('project_copy: ${probeRoot.path}');
  stdout.writeln('passed: ${recorder.passedCount}');
  stdout.writeln('failed: ${recorder.failedCount}');
  stdout.writeln('report: $reportPath');
  for (final step in recorder.steps) {
    final prefix = step['ok'] == true ? '[PASS]' : '[FAIL]';
    stdout.writeln('$prefix ${step['name']}');
    final detail = '${step['detail'] ?? ''}'.trim();
    if (detail.isNotEmpty) {
      stdout.writeln('  $detail');
    }
  }
  if (recorder.failedCount > 0) {
    exitCode = 1;
  }
}

Future<ProjectDescriptor> _resolveSourceProject(AdapterBundle bundle) async {
  // 中文注释: 优先复用当前用户设置里的默认项目，确保探针覆盖真实用户工作区结构。
  final settings = await bundle.settingsRepository.load();
  final projectPath = settings.defaultProjectPath.trim();
  if (projectPath.isEmpty) {
    throw StateError('当前没有默认项目路径，无法执行全工具探针。');
  }
  final project = await bundle.projectRepository.openByPath(projectPath);
  if (project == null) {
    throw StateError('默认项目无效：$projectPath');
  }
  return project;
}

Future<Directory> _prepareProbeProject(String sourceRootPath) async {
  // 中文注释: 探针副本放到仓库 artifacts 下，既方便排查，也不会污染正式项目目录。
  final artifactsRoot = Directory('artifacts/tool_probes');
  await artifactsRoot.create(recursive: true);
  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  final target = Directory('${artifactsRoot.path}/probe_$timestamp');
  await _copyDirectory(Directory(sourceRootPath), target);
  return target;
}

Future<void> _copyDirectory(Directory source, Directory target) async {
  await target.create(recursive: true);
  await for (final entity in source.list(
    recursive: false,
    followLinks: false,
  )) {
    final name = entity.uri.pathSegments.isEmpty
        ? ''
        : entity.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);
    if (name.isEmpty) {
      continue;
    }
    final targetPath = '${target.path}${Platform.pathSeparator}$name';
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(targetPath));
      continue;
    }
    if (entity is File) {
      await File(targetPath).create(recursive: true);
      await entity.copy(targetPath);
    }
  }
}

Future<void> _seedProbeFixtures(
  ProjectWorkspacePort workspacePort,
  ProjectDescriptor project,
) async {
  // 中文注释: 这里统一补齐探针所需的最小测试材料，避免不同工具各自隐式依赖用户现有文件。
  await workspacePort.writeTextFile(
    project.rootPath,
    'chapters/probe_source.md',
    '# Probe Source\n\nAlpha line.\nBeta line.\nGamma line.\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'chapters/probe_target.md',
    'Existing target header.\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'sessions/probe_session.json',
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'id': 'probe_session',
      'title': '探针会话',
      'mode': 'smart_opening',
      'workflow_stage': 'draft',
      'public_status': '进行中',
      'updated_at': '2026-05-25T00:00:00Z',
      'context_messages': <Object?>[
        <String, Object?>{'role': 'user', 'content': 'hi'},
        <String, Object?>{'role': 'assistant', 'content': 'hello'},
      ],
    }),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'sessions/session_index.json',
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'current_session_id': 'probe_session',
      'sessions': <Object?>[
        <String, Object?>{
          'id': 'probe_session',
          'title': '探针会话',
          'mode': 'smart_opening',
          'workflow_stage': 'draft',
          'public_status': '进行中',
          'updated_at': '2026-05-25T00:00:00Z',
          'message_count': 2,
        },
      ],
    }),
  );
}

Future<HttpServer> _startGatewayProbeServer() async {
  // 中文注释: 网关类工具优先走本地 HTTP 夹具，避免探针结果受外网波动影响。
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  unawaited(
    server.forEach((request) async {
      if (request.uri.path == '/page') {
        request.response.headers.contentType = ContentType.text;
        request.response.write('Probe page body for fetch_url_content.');
        await request.response.close();
        return;
      }
      if (request.uri.path == '/search') {
        request.response.headers.contentType = ContentType.html;
        request.response.write('''
<html><body>
  <a class="result__a" href="https://example.com/a">结果 A</a>
  <div class="result__snippet">摘要 A</div>
  <a class="result__a" href="https://example.com/b">结果 B</a>
  <div class="result__snippet">摘要 B</div>
</body></html>
''');
        await request.response.close();
        return;
      }
      if (request.uri.path == '/image') {
        request.response.headers.contentType = ContentType.text;
        request.response.write('fake-image-payload');
        await request.response.close();
        return;
      }
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }),
  );
  return server;
}

Future<void> _runProjectToolProbes({
  required AdapterBundle bundle,
  required ProjectDescriptor project,
  required _ProbeRecorder recorder,
  required String gatewayBaseUrl,
}) async {
  final toolPort = bundle.projectToolExecutionPort;
  await recorder.capture('list_project_files', () async {
    final result = await _executeTool(toolPort, project, 'list_project_files');
    final entries = ValueReaders.objectList(result['entries']);
    _ensure(ValueReaders.boolValue(result['ok']), 'list_project_files failed');
    _ensure(entries.isNotEmpty, 'entries should not be empty');
    return 'entries=${entries.length}';
  });
  await recorder.capture('read_project_file', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'read_project_file',
      arguments: <String, Object?>{'relative_path': 'chapters/probe_source.md'},
    );
    final content = ValueReaders.stringValue(result['content']);
    _ensure(content.contains('Alpha line.'), 'probe content missing');
    return 'chars=${content.length}';
  });
  await recorder.capture('read_project_file.line_window', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'read_project_file',
      arguments: <String, Object?>{
        'relative_path': 'chapters/probe_source.md',
        'start_line': 2,
        'limit': 2,
      },
    );
    final content = ValueReaders.stringValue(result['content']);
    _ensure(
      content.contains('3: Alpha line.'),
      'line window should include line numbers',
    );
    _ensure(
      ValueReaders.intValue(result['selected_end_line']) == 3,
      'line window end line mismatch',
    );
    return 'window=${result['selected_start_line']}-${result['selected_end_line']}';
  });
  await recorder.capture('get_project_file_info', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'get_project_file_info',
      arguments: <String, Object?>{
        'relative_path': 'chapters/probe_source.md',
        'start_line': 2,
        'end_line': 4,
      },
    );
    final lines = ValueReaders.objectList(result['selected_lines']);
    _ensure(lines.length == 3, 'expected three selected lines');
    return 'selected_lines=${lines.length}';
  });
  await recorder.capture('search_project_files', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'search_project_files',
      arguments: <String, Object?>{'pattern': 'Beta line', 'limit': 5},
    );
    final matches = ValueReaders.objectList(result['matches']);
    _ensure(matches.isNotEmpty, 'search should return match');
    return 'matches=${matches.length}';
  });
  await recorder.capture('write_project_file', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'write_project_file',
      arguments: <String, Object?>{
        'relative_path': 'chapters/probe_written.md',
        'content': '# Written Probe\n\nBody 1\n',
        'overwrite': true,
      },
    );
    final path = ValueReaders.stringValue(result['relative_path']);
    _ensure(
      path == 'chapters/probe_written.md',
      'unexpected write path: $path',
    );
    return path;
  });
  await recorder.capture('edit_project_file', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'edit_project_file',
      arguments: <String, Object?>{
        'relative_path': 'chapters/probe_written.md',
        'operation': 'replace',
        'old_text': 'Body 1',
        'content': 'Body 2',
      },
    );
    _ensure(
      ValueReaders.boolValue(result['changed']),
      'edit should change file',
    );
    return 'changed=${result['changed']}';
  });
  await recorder.capture('edit_project_file.regex_replace', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'edit_project_file',
      arguments: <String, Object?>{
        'relative_path': 'chapters/probe_source.md',
        'operation': 'replace',
        'pattern': r'Alpha|Beta',
        'content': 'Patched',
        'use_regex': true,
      },
    );
    _ensure(
      ValueReaders.boolValue(result['changed']),
      'regex edit should change file',
    );
    return 'replace_count=${result['replace_count']}';
  });
  await recorder.capture('edit_project_file.anchored_range', () async {
    await _executeTool(
      toolPort,
      project,
      'write_project_file',
      arguments: <String, Object?>{
        'relative_path': 'chapters/probe_range.md',
        'content': 'BEGIN\nold body\nEND\n',
        'overwrite': true,
      },
    );
    final result = await _executeTool(
      toolPort,
      project,
      'edit_project_file',
      arguments: <String, Object?>{
        'relative_path': 'chapters/probe_range.md',
        'operation': 'replace',
        'start_text': 'BEGIN\n',
        'end_text': '\nEND',
        'content': 'new body',
      },
    );
    _ensure(
      ValueReaders.boolValue(result['changed']),
      'anchored range edit should change file',
    );
    return 'replace_count=${result['replace_count']}';
  });
  await recorder.capture('manipulate_project_file_lines', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'manipulate_project_file_lines',
      arguments: <String, Object?>{
        'relative_path': 'chapters/probe_source.md',
        'target_relative_path': 'chapters/probe_target.md',
        'operation': 'copy',
        'start_line': 2,
        'end_line': 3,
      },
    );
    final changedPaths = ValueReaders.stringList(result['changed_paths']);
    _ensure(
      changedPaths.contains('chapters/probe_target.md'),
      'target file should be changed',
    );
    return 'changed=${changedPaths.join(', ')}';
  });
  await recorder.capture(
    'manipulate_project_file_lines.negative_lines',
    () async {
      final result = await _executeTool(
        toolPort,
        project,
        'manipulate_project_file_lines',
        arguments: <String, Object?>{
          'sourceRelativePath': 'chapters/probe_source.md',
          'target_relative_path': 'chapters/probe_target.md',
          'operation': 'copy',
          'start_line': -2,
          'end_line': -1,
        },
      );
      _ensure(
        ValueReaders.boolValue(result['ok']),
        'negative line manipulation should succeed',
      );
      return 'selected=${result['selected_start_line']}-${result['selected_end_line']}';
    },
  );
  late String backupPath;
  await recorder.capture('create_backup', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'create_backup',
      arguments: <String, Object?>{
        'relative_path': 'chapters/probe_written.md',
        'reason': 'tool probe backup',
      },
    );
    backupPath = ValueReaders.stringValue(result['backup_path']);
    _ensure(
      backupPath.startsWith('backups/'),
      'backup should be under backups/',
    );
    return backupPath;
  });
  await recorder.capture('delete_project_file', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'delete_project_file',
      arguments: <String, Object?>{
        'relative_path': 'chapters/probe_written.md',
        'create_backup': false,
      },
    );
    _ensure(ValueReaders.boolValue(result['ok']), 'delete should succeed');
    return ValueReaders.stringValue(result['relative_path']);
  });
  await recorder.capture('restore_backup', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'restore_backup',
      arguments: <String, Object?>{'backup_path': backupPath},
    );
    final path = ValueReaders.stringValue(result['relative_path']);
    _ensure(
      path == 'chapters/probe_written.md',
      'restore target mismatch: $path',
    );
    return path;
  });
  await recorder.capture('create_project_entry_folder', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'create_project_entry',
      arguments: <String, Object?>{'relative_path': 'inspiration/probe_folder'},
    );
    _ensure(
      ValueReaders.boolValue(result['is_folder']),
      'should create folder',
    );
    return ValueReaders.stringValue(result['relative_path']);
  });
  await recorder.capture('create_project_entry_file', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'create_project_entry',
      arguments: <String, Object?>{
        'relative_path': 'inspiration/probe_folder/probe_entry.md',
        'content': 'Sandbox file',
      },
    );
    return ValueReaders.stringValue(result['relative_path']);
  });
  await recorder.capture('move_project_file', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'move_project_file',
      arguments: <String, Object?>{
        'relative_path': 'inspiration/probe_folder/probe_entry.md',
        'target_relative_path': 'inspiration/probe_folder/probe_moved.md',
      },
    );
    final path = ValueReaders.stringValue(result['relative_path']);
    _ensure(
      path == 'inspiration/probe_folder/probe_moved.md',
      'move target mismatch: $path',
    );
    return path;
  });
  await recorder.capture('rename_project_file', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'rename_project_file',
      arguments: <String, Object?>{
        'relative_path': 'inspiration/probe_folder/probe_moved.md',
        'new_name': 'probe_renamed.md',
      },
    );
    final path = ValueReaders.stringValue(result['relative_path']);
    _ensure(
      path == 'inspiration/probe_folder/probe_renamed.md',
      'rename target mismatch: $path',
    );
    return path;
  });
  await recorder.capture('reorder_project_file', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'reorder_project_file',
      arguments: <String, Object?>{
        'relative_path': 'inspiration/probe_folder/probe_renamed.md',
        'target_index': 0,
      },
    );
    final siblings = ValueReaders.stringList(result['ordered_siblings']);
    _ensure(siblings.isNotEmpty, 'reorder should return sibling order');
    return 'siblings=${siblings.join(', ')}';
  });
  await recorder.capture('present_user_options', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'present_user_options',
      arguments: <String, Object?>{
        'question': '请选择方向',
        'choices': <Object?>[
          <String, Object?>{'title': '方案一', 'value': '我选择方案一'},
          <String, Object?>{'title': '方案二', 'value': '我选择方案二'},
        ],
      },
    );
    final options = ValueReaders.objectList(result['options']);
    _ensure(options.length == 2, 'expected 2 options');
    _ensure(
      ValueReaders.boolValue(result['waiting_for_user_choice']),
      'present_user_options should wait for user choice',
    );
    return 'options=${options.length}';
  });
  await recorder.capture('set_agent_tasks', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'set_agent_tasks',
      arguments: <String, Object?>{
        'goal': '完成探针',
        'tasks': <Object?>[
          <String, Object?>{'title': '检查读写'},
          <String, Object?>{'title': '检查网关'},
        ],
      },
    );
    final tasks = ValueReaders.objectList(result['tasks']);
    _ensure(tasks.length == 2, 'expected 2 tasks');
    return 'tasks=${tasks.length}';
  });
  await recorder.capture('load_agent_skill', () async {
    final preview = await toolPort.execute(
      project: project,
      toolCall: <String, Object?>{
        'id': 'load_agent_skill_preview',
        'name': 'load_agent_skill',
        'arguments': const <String, Object?>{},
      },
    );
    _ensure(
      ValueReaders.boolValue(preview['not_executed']),
      'load_agent_skill preview should return available_skills',
    );
    final available = ValueReaders.objectList(
      preview['available_skills'],
    ).map(ValueReaders.mapValue).toList(growable: false);
    _ensure(available.isNotEmpty, 'available skills should not be empty');
    final firstSkillId = ValueReaders.stringValue(available.first['id']);
    final result = await _executeTool(
      toolPort,
      project,
      'load_agent_skill',
      arguments: <String, Object?>{'skill_id': firstSkillId},
    );
    final instructions = ValueReaders.stringValue(result['instructions']);
    _ensure(instructions.trim().isNotEmpty, 'skill instructions should exist');
    return firstSkillId;
  });
  await recorder.capture('update_world_state', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'update_world_state',
      arguments: <String, Object?>{
        'title': 'Probe World',
        'entry_type': 'location',
        'keywords': <Object?>['probe', 'world'],
        'content': 'A probe-generated world note.',
      },
    );
    return ValueReaders.stringValue(result['relative_path']);
  });
  await recorder.capture('update_character_state', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'update_character_state',
      arguments: <String, Object?>{
        'name': 'Probe Hero',
        'role': '主角',
        'status': '在线',
        'content': '角色探针档案。',
      },
    );
    return ValueReaders.stringValue(result['relative_path']);
  });
  await recorder.capture('summarize_context', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'summarize_context',
      arguments: <String, Object?>{
        'title': 'Probe Summary',
        'scope': 'tool_probe',
        'summary': '本轮探针验证了核心工具链。',
      },
    );
    return ValueReaders.stringValue(result['relative_path']);
  });
  await recorder.capture('run_continuity_check', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'run_continuity_check',
      arguments: <String, Object?>{
        'title': 'Probe Review',
        'summary': '整体一致。',
        'issues': <Object?>[
          <String, Object?>{
            'title': '样例问题',
            'severity': 'low',
            'description': '仅用于探针验证。',
          },
        ],
        'suggestions': <Object?>['继续保持'],
      },
    );
    final jsonPath = ValueReaders.stringValue(result['json_path']);
    _ensure(jsonPath.endsWith('.json'), 'review json path missing');
    return '${result['markdown_path']} | $jsonPath';
  });
  late String taskId;
  await recorder.capture('create_chapter_task', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'create_chapter_task',
      arguments: <String, Object?>{
        'title': 'Probe Chapter Task',
        'goal': '验证任务落盘',
        'chapter_index': 1,
      },
    );
    final task = ValueReaders.mapValue(result['task']);
    taskId = ValueReaders.stringValue(task['id']);
    _ensure(taskId.isNotEmpty, 'task id missing');
    return ValueReaders.stringValue(result['relative_path']);
  });
  await recorder.capture('mark_task_status', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'mark_task_status',
      arguments: <String, Object?>{
        'task_id': taskId,
        'status': 'done',
        'note': 'tool probe completed',
      },
    );
    final task = ValueReaders.mapValue(result['task']);
    _ensure(task['status'] == 'done', 'task status should become done');
    return ValueReaders.stringValue(result['relative_path']);
  });
  await recorder.capture('list_history_sessions', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'list_history_sessions',
    );
    final sessions = ValueReaders.objectList(result['sessions']);
    _ensure(sessions.isNotEmpty, 'history sessions should not be empty');
    return 'sessions=${sessions.length}';
  });
  await recorder.capture('rename_project', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'rename_project',
      arguments: <String, Object?>{'new_name': 'Probe Project Renamed'},
    );
    final title = ValueReaders.stringValue(result['project_title']);
    _ensure(title == 'Probe Project Renamed', 'rename_project failed');
    return title;
  });
  await recorder.capture('request_gateway_tool.fetch_url_content', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'request_gateway_tool',
      arguments: <String, Object?>{
        'gateway_tool': 'fetch_url_content',
        'url': '$gatewayBaseUrl/page',
      },
    );
    final content = ValueReaders.stringValue(result['content']);
    _ensure(content.contains('Probe page body'), 'fetch content mismatch');
    return 'status=${result['status_code']}';
  });
  await recorder.capture('request_gateway_tool.search_internet', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'request_gateway_tool',
      arguments: <String, Object?>{
        'gateway_tool': 'search_internet',
        'query': 'probe query',
        'search_url': '$gatewayBaseUrl/search',
        'limit': 2,
      },
    );
    final items = ValueReaders.objectList(result['results']);
    _ensure(items.length == 2, 'search results should contain 2 items');
    return 'results=${items.length}';
  });
  await recorder.capture('request_gateway_tool.run_command', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'request_gateway_tool',
      arguments: <String, Object?>{
        'gateway_tool': 'run_command',
        'command': 'Write-Output probe_command_ok',
      },
    );
    final stdoutText = ValueReaders.stringValue(result['stdout']);
    _ensure(stdoutText.contains('probe_command_ok'), 'command stdout mismatch');
    return 'exit=${result['exit_code']}';
  });
  await recorder.capture('request_gateway_tool.generate_image', () async {
    final result = await _executeTool(
      toolPort,
      project,
      'request_gateway_tool',
      arguments: <String, Object?>{
        'gateway_tool': 'generate_image',
        'image_url': '$gatewayBaseUrl/image',
        'relative_path': 'assets/probe_image.txt',
      },
    );
    final content = ValueReaders.stringValue(result['content']);
    _ensure(
      content.contains('fake-image-payload'),
      'image probe content mismatch',
    );
    return ValueReaders.stringValue(result['relative_path']);
  });
}

Future<void> _runSubAgentProbe({
  required ProjectDescriptor project,
  required _ProbeRecorder recorder,
}) async {
  await recorder.capture('call_sub_agent', () async {
    final service = SubAgentExecutionService(
      llmGateway: _FakeLlmGateway(),
      toolExecutionPort: _FailingUnexpectedToolPort(),
    );
    final result = await service.execute(
      project: project,
      parentAgent: const <String, Object?>{
        'id': 'default_generalist',
        'name': '通用主智能体',
      },
      toolCall: const <String, Object?>{
        'id': 'call_sub_probe',
        'name': 'call_sub_agent',
        'arguments': <String, Object?>{'task': '请给出一句简短的探针结论。'},
      },
      modelId: 'probe-model',
      mainContext: const <String, Object?>{'intent': 'draft'},
    );
    _ensure(ValueReaders.boolValue(result['ok']), 'call_sub_agent failed');
    final content = ValueReaders.stringValue(result['result_markdown']);
    _ensure(content.contains('子智能体探针执行成功'), 'sub agent content mismatch');
    return ValueReaders.stringValue(result['summary']);
  });
}

Future<JsonMap> _executeTool(
  ToolExecutionPort toolPort,
  ProjectDescriptor project,
  String toolName, {
  JsonMap arguments = const <String, Object?>{},
}) async {
  final result = await toolPort.execute(
    project: project,
    toolCall: <String, Object?>{
      'id': '${toolName}_${DateTime.now().microsecondsSinceEpoch}',
      'name': toolName,
      'arguments': arguments,
    },
  );
  _ensure(
    ValueReaders.boolValue(result['ok']),
    _toolFailureMessage(toolName, result),
  );
  return result;
}

String _toolFailureMessage(String toolName, JsonMap result) {
  final error = ValueReaders.stringValue(result['error']).trim();
  return error.isEmpty
      ? '$toolName returned non-ok result.'
      : '$toolName failed: $error';
}

Future<String> _writeReport({
  required Directory probeRoot,
  required ProjectDescriptor sourceProject,
  required _ProbeRecorder recorder,
}) async {
  final report = <String, Object?>{
    'created_at': DateTime.now().toIso8601String(),
    'source_project_path': sourceProject.rootPath,
    'probe_project_path': probeRoot.path,
    'passed': recorder.passedCount,
    'failed': recorder.failedCount,
    'steps': recorder.steps,
  };
  final reportPath =
      '${probeRoot.path}${Platform.pathSeparator}tool_probe_report.json';
  await File(
    reportPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  return reportPath;
}

void _ensure(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

class _ProbeRecorder {
  final List<JsonMap> steps = <JsonMap>[];

  int get passedCount =>
      steps.where((step) => ValueReaders.boolValue(step['ok'])).length;

  int get failedCount =>
      steps.where((step) => !ValueReaders.boolValue(step['ok'])).length;

  Future<void> capture(String name, Future<String> Function() action) async {
    final startedAt = DateTime.now();
    try {
      final detail = await action();
      steps.add(<String, Object?>{
        'name': name,
        'ok': true,
        'detail': detail,
        'started_at': startedAt.toIso8601String(),
        'finished_at': DateTime.now().toIso8601String(),
      });
    } catch (error, stackTrace) {
      steps.add(<String, Object?>{
        'name': name,
        'ok': false,
        'detail': '$error',
        'stack_trace': '$stackTrace',
        'started_at': startedAt.toIso8601String(),
        'finished_at': DateTime.now().toIso8601String(),
      });
    }
  }
}

class _FakeLlmGateway extends LlmGateway {
  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    return <String, Object?>{
      'ok': true,
      'content': '子智能体探针执行成功。',
      'message': const <String, Object?>{
        'role': 'assistant',
        'content': '子智能体探针执行成功。',
        'tool_calls': <Object?>[],
      },
      'tool_calls': const <Object?>[],
    };
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async {
    return '子智能体探针执行成功。';
  }
}

class _FailingUnexpectedToolPort implements ToolExecutionPort {
  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    throw StateError(
      'Sub-agent probe should not reach nested tool execution: ${toolCall['name']}',
    );
  }
}
