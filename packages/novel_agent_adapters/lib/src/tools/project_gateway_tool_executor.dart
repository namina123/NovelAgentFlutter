import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_gateway_http_service.dart';
import 'project_gateway_process_service.dart';
import 'project_tool_path_policy.dart';
import 'project_tool_result_factory.dart';

class ProjectGatewayToolExecutor {
  ProjectGatewayToolExecutor({
    ProjectGatewayHttpService? httpService,
    ProjectGatewayProcessService? processService,
    ProjectToolResultFactory? resultFactory,
    ProjectToolPathPolicy? pathPolicy,
  }) : _httpService = httpService ?? ProjectGatewayHttpService(),
       _processService = processService ?? ProjectGatewayProcessService(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy();

  final ProjectGatewayHttpService _httpService;
  final ProjectGatewayProcessService _processService;
  final ProjectToolResultFactory _resultFactory;
  final ProjectToolPathPolicy _pathPolicy;

  Future<JsonMap> execute(ProjectDescriptor project, JsonMap arguments) async {
    // 中文注释: Gateway 工具在这里统一拆分为联网、命令与媒体三类，避免管理执行器继续膨胀。
    final gatewayTool = ValueReaders.stringValue(
      arguments['gateway_tool'],
      ValueReaders.stringValue(
        arguments['tool'],
        ValueReaders.stringValue(arguments['name']),
      ),
    ).trim();
    if (gatewayTool.isEmpty) {
      return _resultFactory.error('gateway_tool is required.');
    }
    final mergedArguments = _mergedArguments(arguments);
    switch (gatewayTool) {
      case 'fetch_url_content':
        return _fetchUrlContent(gatewayTool, mergedArguments);
      case 'search_internet':
        return _searchInternet(gatewayTool, mergedArguments);
      case 'run_command':
        return _runCommand(gatewayTool, mergedArguments);
      case 'generate_image':
        return _generateImage(project, gatewayTool, mergedArguments);
      default:
        return _resultFactory.error(
          'Unknown gateway tool: $gatewayTool',
          data: <String, Object?>{
            'gateway_tool': gatewayTool,
            'platform_policy': 'desktop_or_gateway_only',
          },
        );
    }
  }

  Future<JsonMap> _fetchUrlContent(
    String gatewayTool,
    JsonMap arguments,
  ) async {
    // 中文注释: URL 抓取工具保持纯文本返回，后续是否摘要、引用或缓存由更上层链路决定。
    final url = ValueReaders.stringValue(
      arguments['url'],
      ValueReaders.stringValue(arguments['link']),
    ).trim();
    if (url.isEmpty) {
      return _resultFactory.error(
        'url is required.',
        data: <String, Object?>{'gateway_tool': gatewayTool},
      );
    }
    try {
      final result = await _httpService.fetchText(
        url: url,
        method: ValueReaders.stringValue(arguments['method'], 'GET'),
        headers: ValueReaders.mapValue(arguments['headers']),
        body: ValueReaders.stringValue(arguments['body']),
        maxChars: ValueReaders.intValue(arguments['max_chars'], 24000),
      );
      return _resultFactory.success(
        '已抓取远程内容：$url',
        data: <String, Object?>{
          'gateway_tool': gatewayTool,
          'url': url,
          'status_code': result.statusCode,
          'content_type': result.contentType,
          'content': result.body,
          'truncated': result.truncated,
          'platform_policy': 'desktop_or_gateway_only',
        },
      );
    } catch (error) {
      return _resultFactory.error(
        '远程抓取失败：$error',
        data: <String, Object?>{
          'gateway_tool': gatewayTool,
          'url': url,
          'platform_policy': 'desktop_or_gateway_only',
        },
      );
    }
  }

  Future<JsonMap> _searchInternet(String gatewayTool, JsonMap arguments) async {
    // 中文注释: 搜索工具默认走轻量网页搜索，优先返回结构化结果，必要时再附带截断后的原始 HTML。
    final query = ValueReaders.stringValue(
      arguments['query'],
      ValueReaders.stringValue(
        arguments['keyword'],
        ValueReaders.stringValue(arguments['q']),
      ),
    ).trim();
    if (query.isEmpty) {
      return _resultFactory.error(
        'query is required.',
        data: <String, Object?>{'gateway_tool': gatewayTool},
      );
    }
    final limit = ValueReaders.intValue(arguments['limit'], 5).clamp(1, 10);
    final searchUrl = ValueReaders.stringValue(
      arguments['search_url'],
      'https://html.duckduckgo.com/html/?q=${Uri.encodeQueryComponent(query)}',
    );
    try {
      final result = await _httpService.fetchText(
        url: searchUrl,
        headers: const <String, Object?>{
          'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8',
        },
        maxChars: ValueReaders.intValue(arguments['max_chars'], 32000),
      );
      final searchResults = _httpService.parseSearchResults(
        result.body,
        limit: limit,
      );
      return _resultFactory.success(
        '已完成联网搜索：$query',
        data: <String, Object?>{
          'gateway_tool': gatewayTool,
          'query': query,
          'search_url': searchUrl,
          'status_code': result.statusCode,
          'results': searchResults,
          'content': result.body,
          'truncated': result.truncated,
          'platform_policy': 'desktop_or_gateway_only',
        },
      );
    } catch (error) {
      return _resultFactory.error(
        '联网搜索失败：$error',
        data: <String, Object?>{
          'gateway_tool': gatewayTool,
          'query': query,
          'platform_policy': 'desktop_or_gateway_only',
        },
      );
    }
  }

  Future<JsonMap> _runCommand(String gatewayTool, JsonMap arguments) async {
    // 中文注释: 宿主命令执行返回 stdout/stderr 与真实计划，便于 GUI/CLI 做回放和诊断。
    try {
      final result = await _processService.runCommand(arguments);
      return _resultFactory.success(
        '已执行宿主命令：${result.executable}',
        data: <String, Object?>{
          'gateway_tool': gatewayTool,
          'executable': result.executable,
          'arguments_list': result.arguments,
          'exit_code': result.exitCode,
          'stdout': result.stdout,
          'stderr': result.stderr,
          'platform_policy': 'desktop_or_gateway_only',
        },
      );
    } catch (error) {
      return _resultFactory.error(
        '宿主命令执行失败：$error',
        data: <String, Object?>{
          'gateway_tool': gatewayTool,
          'platform_policy': 'desktop_or_gateway_only',
        },
      );
    }
  }

  Future<JsonMap> _generateImage(
    ProjectDescriptor project,
    String gatewayTool,
    JsonMap arguments,
  ) async {
    // 中文注释: 图片网关优先支持把外部图片 URL 落入项目目录，避免先把生成能力和供应商协议硬耦在一起。
    final imageUrl = ValueReaders.stringValue(
      arguments['image_url'],
      ValueReaders.stringValue(arguments['url']),
    ).trim();
    final targetRelativePath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(
        arguments['relative_path'],
        ValueReaders.stringValue(arguments['output_relative_path']),
      ),
    );
    if (imageUrl.isEmpty || targetRelativePath.isEmpty) {
      return _resultFactory.error(
        'generate_image 当前需要提供 image_url 与 relative_path 才能落盘。',
        data: <String, Object?>{
          'gateway_tool': gatewayTool,
          'platform_policy': 'desktop_or_gateway_only',
        },
      );
    }
    if (!_pathPolicy.isSafeFilePath(targetRelativePath)) {
      return _resultFactory.error(
        'Unsafe relative_path.',
        data: <String, Object?>{
          'gateway_tool': gatewayTool,
          'relative_path': targetRelativePath,
        },
      );
    }
    try {
      final result = await _httpService.fetchText(
        url: imageUrl,
        maxChars: ValueReaders.intValue(arguments['max_chars'], 200000),
      );
      return _resultFactory.success(
        '已获取图片网关响应：$imageUrl',
        data: <String, Object?>{
          'gateway_tool': gatewayTool,
          'relative_path': targetRelativePath,
          'status_code': result.statusCode,
          'content_type': result.contentType,
          'content': result.body,
          'truncated': result.truncated,
          'platform_policy': 'desktop_or_gateway_only',
        },
      );
    } catch (error) {
      return _resultFactory.error(
        '图片网关请求失败：$error',
        data: <String, Object?>{
          'gateway_tool': gatewayTool,
          'relative_path': targetRelativePath,
          'platform_policy': 'desktop_or_gateway_only',
        },
      );
    }
  }

  JsonMap _mergedArguments(JsonMap arguments) {
    // 中文注释: 兼容“直接别名调用”和“request_gateway_tool 嵌套 arguments”两种格式，统一只留真实工具参数。
    final nestedArguments = ValueReaders.mapValue(arguments['arguments']);
    final merged = <String, Object?>{...nestedArguments};
    for (final entry in arguments.entries) {
      if (entry.key == 'arguments' ||
          entry.key == 'gateway_tool' ||
          entry.key == 'tool' ||
          entry.key == 'name') {
        continue;
      }
      merged[entry.key] = entry.value;
    }
    return merged;
  }
}
