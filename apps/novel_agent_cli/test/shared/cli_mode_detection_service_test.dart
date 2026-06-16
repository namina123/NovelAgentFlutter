import 'package:novel_agent_cli/commands/shared/cli_mode_detection_service.dart';
import 'package:test/test.dart';

void main() {
  test('prefers explicit non-interactive mode over tty state', () {
    final service = CliModeDetectionService(
      stdinHasTerminal: () => true,
      stdoutHasTerminal: () => true,
    );

    expect(
      service.resolve(explicitInteractive: true, explicitNonInteractive: true),
      CliExecutionMode.nonInteractive,
    );
  });

  test('resolves interactive when terminals are attached', () {
    final service = CliModeDetectionService(
      stdinHasTerminal: () => true,
      stdoutHasTerminal: () => true,
    );

    expect(service.resolve(), CliExecutionMode.interactive);
    expect(service.hasTerminal, isTrue);
  });

  test('falls back to headless when stdin is piped', () {
    final service = CliModeDetectionService(
      stdinHasTerminal: () => false,
      stdoutHasTerminal: () => true,
    );

    expect(service.resolve(), CliExecutionMode.headless);
    expect(
      service.resolve(explicitInteractive: true),
      CliExecutionMode.interactive,
    );
  });
}
