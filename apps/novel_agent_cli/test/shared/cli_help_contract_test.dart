import 'package:novel_agent_cli/commands/shared/cli_help_contract.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:test/test.dart';

void main() {
  test('prints shared help block format', () {
    final printer = _RecordingTerminalPrinter();

    CliHelpContract.printHelpBlock(printer, 'sample help', const <String>[
      'one',
      'two',
    ]);

    expect(printer.blocks, contains('sample help\none\ntwo'));
  });
}

class _RecordingTerminalPrinter extends TerminalPrinter {
  final List<String> blocks = <String>[];

  @override
  void block(String title, String content) {
    blocks.add('$title\n$content');
  }
}
