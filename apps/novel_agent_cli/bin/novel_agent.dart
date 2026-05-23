import 'dart:io';

import 'package:novel_agent_cli/bootstrap/cli_bootstrap.dart';

Future<void> main(List<String> args) async {
  // 中文注释: CLI 入口只负责转交参数并设置退出码，不在入口函数内堆叠命令语义。
  final code = await CliBootstrap().run(args);
  exitCode = code;
}
