import 'package:novel_agent_cli/commands/shared/cli_automation_input_service.dart';
import 'package:novel_agent_cli/commands/shared/cli_mode_detection_service.dart';
import 'package:test/test.dart';

void main() {
  test('resolveMode treats yes as a non-interactive automation hint', () {
    final service = CliAutomationInputService(
      modeDetectionService: const CliModeDetectionService(
        stdinHasTerminal: _alwaysTrue,
        stdoutHasTerminal: _alwaysTrue,
      ),
    );

    expect(
      service.resolveMode(const <String>['--yes']),
      CliExecutionMode.nonInteractive,
    );
    expect(
      service.resolveMode(const <String>['--non-interactive']),
      CliExecutionMode.nonInteractive,
    );
  });

  test(
    'resolveTextInput falls back to piped stdin when not interactive',
    () async {
      var readCount = 0;
      final service = CliAutomationInputService(
        modeDetectionService: const CliModeDetectionService(
          stdinHasTerminal: _alwaysFalse,
          stdoutHasTerminal: _alwaysTrue,
        ),
        stdinHasTerminal: _alwaysFalse,
        stdinReader: () async {
          readCount += 1;
          return '  hello from pipe  \n';
        },
      );

      final resolved = await service.resolveTextInput(
        const <String>['--non-interactive'],
        optionNames: const <String>['--message'],
      );

      expect(resolved, 'hello from pipe');
      expect(readCount, 1);
    },
  );

  test(
    'resolveTextInput does not read stdin in interactive terminal mode',
    () async {
      var readCount = 0;
      final service = CliAutomationInputService(
        modeDetectionService: const CliModeDetectionService(
          stdinHasTerminal: _alwaysTrue,
          stdoutHasTerminal: _alwaysTrue,
        ),
        stdinHasTerminal: _alwaysTrue,
        stdinReader: () async {
          readCount += 1;
          return 'unused';
        },
      );

      final resolved = await service.resolveTextInput(
        const <String>['--message', 'hello'],
        optionNames: const <String>['--message'],
      );

      expect(resolved, 'hello');
      expect(readCount, 0);
    },
  );
}

bool _alwaysTrue() => true;

bool _alwaysFalse() => false;
