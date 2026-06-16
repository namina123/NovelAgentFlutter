import 'cli_log_level.dart';
import 'cli_output_settings.dart';

class CliProgressReporter {
  const CliProgressReporter(this.settings, this.report);

  final CliOutputSettings settings;
  final void Function(String message) report;

  void start(String message) {
    // 中文注释: 进度报告只是壳层提示，不承载业务状态，后续可接到更细粒度进度流。
    if (settings.logLevel == CliLogLevel.quiet) {
      return;
    }
    report(message);
  }

  void update(String message) {
    if (settings.logLevel == CliLogLevel.quiet) {
      return;
    }
    report(message);
  }

  void finish(String message) {
    if (settings.logLevel == CliLogLevel.quiet) {
      return;
    }
    report(message);
  }
}
