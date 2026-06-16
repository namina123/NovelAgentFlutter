import 'dart:async';
import 'dart:convert';

import 'package:novel_agent_cli/bootstrap/cli_bootstrap.dart';
import 'package:novel_agent_cli/output/cli_json_output_writer.dart';
import 'package:novel_agent_cli/output/cli_log_level.dart';
import 'package:novel_agent_cli/output/cli_output_mode.dart';
import 'package:novel_agent_cli/output/cli_output_settings.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:test/test.dart';

void main() {
  group('CliOutputSettings', () {
    test('parses global output flags and strips them from command args', () {
      final settings = CliOutputSettings.fromArgs(const <String>[
        '--json',
        '--quiet',
        '--no-color',
        'help',
        '--project',
        'D:/Novel',
      ]);
      final stripped = CliOutputSettings.stripGlobalFlags(const <String>[
        '--json',
        '--quiet',
        '--no-color',
        'help',
        '--project',
        'D:/Novel',
      ]);

      expect(settings.mode, CliOutputMode.json);
      expect(settings.logLevel, CliLogLevel.quiet);
      expect(settings.noColor, isTrue);
      expect(stripped, <String>['help', '--project', 'D:/Novel']);
    });

    test('prefers debug over verbose and quiet when multiple flags exist', () {
      final settings = CliOutputSettings.fromArgs(const <String>[
        '--quiet',
        '--verbose',
        '--debug',
      ]);

      expect(settings.logLevel, CliLogLevel.debug);
    });
  });

  group('TerminalPrinter', () {
    test('routes text mode output to stdout and stderr sinks', () {
      final stdoutLines = <String>[];
      final stderrLines = <String>[];
      final printer = TerminalPrinter(
        settings: const CliOutputSettings(),
        stdoutSink: stdoutLines.add,
        stderrSink: stderrLines.add,
      );

      printer.info('hello');
      printer.success('done');
      printer.block('title', 'body');
      printer.error('boom');

      expect(stdoutLines, <String>['hello', '[OK] done', '== title ==\nbody']);
      expect(stderrLines, <String>['[ERR] boom']);
    });

    test('suppresses non-error text output in quiet mode', () {
      final stdoutLines = <String>[];
      final stderrLines = <String>[];
      final printer = TerminalPrinter(
        settings: const CliOutputSettings(logLevel: CliLogLevel.quiet),
        stdoutSink: stdoutLines.add,
        stderrSink: stderrLines.add,
      );

      printer.info('hello');
      printer.success('done');
      printer.block('title', 'body');
      printer.error('boom');

      expect(stdoutLines, isEmpty);
      expect(stderrLines, <String>['[ERR] boom']);
    });

    test('writes JSON events when json mode is enabled', () {
      final stdoutLines = <String>[];
      final stderrLines = <String>[];
      final jsonWriter = CliJsonOutputWriter(
        stdoutSink: stdoutLines.add,
        stderrSink: stderrLines.add,
      );
      final printer = TerminalPrinter(
        settings: const CliOutputSettings(mode: CliOutputMode.json),
        jsonWriter: jsonWriter,
      );

      printer.info('hello');
      printer.success('done');
      printer.block('title', 'body');
      printer.error('boom');

      expect(stdoutLines, <String>[
        jsonEncode(<String, Object?>{'type': 'info', 'message': 'hello'}),
        jsonEncode(<String, Object?>{'type': 'success', 'message': 'done'}),
        jsonEncode(<String, Object?>{
          'type': 'block',
          'title': 'title',
          'content': 'body',
        }),
      ]);
      expect(stderrLines, <String>[
        jsonEncode(<String, Object?>{'type': 'error', 'message': 'boom'}),
      ]);
    });
  });

  test(
    'bootstrap switches the same help command between text and json output',
    () async {
      final textLines = await _captureStdout(() async {
        final exitCode = await CliBootstrap().run(<String>['help']);
        expect(exitCode, 0);
      });
      final jsonLines = await _captureStdout(() async {
        final exitCode = await CliBootstrap().run(<String>['--json', 'help']);
        expect(exitCode, 0);
      });

      expect(textLines.single, contains('== novel_agent help ==\n'));
      expect(textLines.single, contains('workflow draft --prompt "写第一章开场"'));
      expect(
        textLines.single,
        contains('approval list --project D:\\YourNovel'),
      );
      expect(textLines.single, contains('config show'));
      expect(textLines.single, contains('doctor'));
      expect(jsonLines.length, greaterThanOrEqualTo(1));
      expect(jsonLines.first, contains('"type":"block"'));
      expect(jsonLines.first, contains('"title":"novel_agent help"'));
    },
  );
}

Future<List<String>> _captureStdout(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) {
        lines.add(line);
      },
    ),
  );
  return lines;
}
