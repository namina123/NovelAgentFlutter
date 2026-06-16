import 'package:novel_agent_cli/commands/shared/cli_arguments.dart';
import 'package:test/test.dart';

void main() {
  test('reads values, flags, and positional text through shared parser', () {
    const args = <String>[
      '--prompt',
      '写第一章',
      '--chapters=8',
      '--no-save',
      '--source',
      'a.txt',
      '--source',
      'b.txt',
      '尾部文本',
    ];
    final parsed = CliArguments(args);

    expect(parsed.value('--prompt'), '写第一章');
    expect(parsed.intValue('--chapters', 0), 8);
    expect(parsed.boolValue('--no-save', false), isTrue);
    expect(parsed.values('--source'), <String>['a.txt', 'b.txt']);
    expect(parsed.positionalText(), '尾部文本');
  });

  test('reports unknown flags against a shared allowlist', () {
    const args = <String>['--known', '1', '--bogus', '--also-known=value'];
    final parsed = CliArguments(args);

    expect(parsed.unknownFlags(<String>{'--known', '--also-known'}), <String>[
      '--bogus',
    ]);
  });
}
