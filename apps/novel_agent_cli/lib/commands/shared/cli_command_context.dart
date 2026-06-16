import 'package:novel_agent_core/novel_agent_core.dart';

class CliCommandContext {
  const CliCommandContext({
    required this.settings,
    required this.defaultProjectPath,
  });

  final AppSettings settings;
  final String defaultProjectPath;
}

class CliProjectContext {
  const CliProjectContext({
    required this.commandContext,
    required this.project,
    required this.projectPath,
  });

  final CliCommandContext commandContext;
  final ProjectDescriptor project;
  final String projectPath;

  AppSettings get settings => commandContext.settings;
}
