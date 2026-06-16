part of 'config_command.dart';

void _printConfigHelp(ConfigCommand command) {
  // 中文注释: config help 只展示正式 settings 读写入口，避免把内部 JSON 结构直接暴露成第二套 UI。
  CliHelpContract.printHelpBlock(command._printer, 'config help', [
    'config show',
    'config get --key default_model_id',
    'config set --key default_model_id --value gpt-4',
    'config get --key draft_fallback_protection',
    'config provider list',
  ]);
}

String _prettyJson(JsonMap value) {
  // 中文注释: config 输出统一缩进，便于文本模式和 JSON 模式共享同一份稳定投影。
  return const JsonEncoder.withIndent('  ').convert(value);
}
