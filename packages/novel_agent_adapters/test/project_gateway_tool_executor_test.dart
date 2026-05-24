import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectGatewayToolExecutor', () {
    test('fetch_url_content returns remote text content', () async {
      // 中文注释: 本地 HTTP 服务器用于验证 gateway 抓取链路已真实接通，而不是继续返回未执行占位结果。
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      try {
        server.listen((request) async {
          request.response.headers.contentType = ContentType.text;
          request.response.write('hello from gateway');
          await request.response.close();
        });
        final executor = ProjectGatewayToolExecutor();
        final result = await executor.execute(
          const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          <String, Object?>{
            'gateway_tool': 'fetch_url_content',
            'url': 'http://127.0.0.1:${server.port}/hello',
          },
        );
        expect(result['ok'], isTrue);
        expect(ValueReaders.stringValue(result['content']), contains('hello'));
      } finally {
        await server.close(force: true);
      }
    });

    test('run_command delegates to process runner with shell plan', () async {
      // 中文注释: 这里用假进程执行器验证命令工具的计划展开和结果回填，避免测试依赖真实宿主命令。
      final fakeRunner = _FakeProcessRunner();
      final executor = ProjectGatewayToolExecutor(
        processService: ProjectGatewayProcessService(processRunner: fakeRunner),
      );
      final result = await executor.execute(
        const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        <String, Object?>{
          'gateway_tool': 'run_command',
          'command': 'echo hello',
        },
      );
        expect(result['ok'], isTrue);
        expect(ValueReaders.stringValue(result['stdout']), 'ok');
        if (Platform.isWindows) {
          expect(fakeRunner.lastExecutable, 'powershell');
          expect(fakeRunner.lastArguments, contains('-Command'));
        } else {
          expect(fakeRunner.lastExecutable, '/bin/sh');
          expect(fakeRunner.lastArguments, contains('-lc'));
        }
    });
  });
}

class _FakeProcessRunner implements ProcessRunner {
  String lastExecutable = '';
  List<String> lastArguments = const <String>[];

  @override
  Future<ProcessRunResult> run({
    required String executable,
    required List<String> arguments,
    String? workingDirectory,
    Duration? timeout,
  }) async {
    // 中文注释: 测试替身只记录计划参数并返回稳定输出，帮助聚焦 gateway 命令工具的路由行为。
    lastExecutable = executable;
    lastArguments = arguments;
    return const ProcessRunResult(exitCode: 0, stdout: 'ok', stderr: '');
  }
}
