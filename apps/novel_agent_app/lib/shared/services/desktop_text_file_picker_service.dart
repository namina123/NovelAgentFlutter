import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';

class DesktopTextFilePickerService {
  const DesktopTextFilePickerService();

  Future<String?> pickSingleFile({required String dialogTitle}) async {
    final results = await pickFiles(
      dialogTitle: dialogTitle,
      allowMultiple: false,
    );
    return results.isEmpty ? null : results.first;
  }

  Future<List<String>> pickFiles({
    required String dialogTitle,
    bool allowMultiple = false,
  }) async {
    if (Platform.isWindows) {
      return _pickOnWindows(
        dialogTitle: dialogTitle,
        allowMultiple: allowMultiple,
      );
    }
    if (Platform.isMacOS) {
      return _pickOnMacOs(
        dialogTitle: dialogTitle,
        allowMultiple: allowMultiple,
      );
    }
    if (Platform.isLinux) {
      return _pickOnLinux(
        dialogTitle: dialogTitle,
        allowMultiple: allowMultiple,
      );
    }
    return const <String>[];
  }

  Future<List<String>> _pickOnWindows({
    required String dialogTitle,
    required bool allowMultiple,
  }) async {
    final result = await Process.run('powershell', <String>[
      '-NoProfile',
      '-STA',
      '-Command',
      '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.OpenFileDialog
\$dialog.Title = "${_escapePowerShell(dialogTitle)}"
\$dialog.Filter = "${const SourceDocumentFormatCatalogService().buildOpenFileDialogFilter()}"
\$dialog.Multiselect = \$${allowMultiple ? 'true' : 'false'}
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::Out.Write((\$dialog.FileNames -join "`n"))
}
''',
    ]);
    return _normalizeSelection(result);
  }

  Future<List<String>> _pickOnMacOs({
    required String dialogTitle,
    required bool allowMultiple,
  }) async {
    final prompt = dialogTitle.replaceAll('"', r'\"');
    final script = <String>[
      '-e',
      allowMultiple
          ? 'set selectedFiles to choose file with prompt "$prompt" with multiple selections allowed'
          : 'set selectedFile to choose file with prompt "$prompt"',
    ];
    if (allowMultiple) {
      script.addAll(<String>[
        '-e',
        'set outputLines to {}',
        '-e',
        'repeat with itemFile in selectedFiles',
        '-e',
        'copy POSIX path of itemFile to end of outputLines',
        '-e',
        'end repeat',
        '-e',
        'return outputLines as string',
      ]);
    } else {
      script.addAll(<String>['-e', 'POSIX path of selectedFile']);
    }
    final result = await Process.run('osascript', script);
    return _normalizeSelection(result, separator: allowMultiple ? ', ' : '\n');
  }

  Future<List<String>> _pickOnLinux({
    required String dialogTitle,
    required bool allowMultiple,
  }) async {
    final args = <String>['--file-selection', '--title=$dialogTitle'];
    if (allowMultiple) {
      args.addAll(<String>['--multiple', '--separator=\n']);
    }
    final result = await Process.run('zenity', args);
    return _normalizeSelection(result);
  }

  List<String> _normalizeSelection(
    ProcessResult result, {
    String separator = '\n',
  }) {
    if (result.exitCode != 0) {
      return const <String>[];
    }
    final output = result.stdout?.toString().trim() ?? '';
    if (output.isEmpty) {
      return const <String>[];
    }
    return output
        .split(separator)
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
  }

  String _escapePowerShell(String value) {
    return value.replaceAll('"', '`"');
  }
}
