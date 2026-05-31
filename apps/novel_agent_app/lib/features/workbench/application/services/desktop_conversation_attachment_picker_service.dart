import 'dart:io';

import 'conversation_attachment_picker_service.dart';

class DesktopConversationAttachmentPickerService
    extends ConversationAttachmentPickerService {
  const DesktopConversationAttachmentPickerService();

  @override
  Future<List<String>> pickFiles() async {
    if (Platform.isWindows) {
      return _pickOnWindows();
    }
    if (Platform.isMacOS) {
      return _pickOnMacOs();
    }
    if (Platform.isLinux) {
      return _pickOnLinux();
    }
    return const <String>[];
  }

  Future<List<String>> _pickOnWindows() async {
    final result = await Process.run('powershell', <String>[
      '-NoProfile',
      '-STA',
      '-Command',
      r'''
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title = "选择会话附件"
$dialog.Filter = "所有文件|*.*"
$dialog.Multiselect = $true
if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::Out.Write(($dialog.FileNames -join "`n"))
}
''',
    ]);
    return _normalizeSelection(result);
  }

  Future<List<String>> _pickOnMacOs() async {
    final result = await Process.run('osascript', <String>[
      '-e',
      'set selectedFiles to choose file with prompt "选择会话附件" with multiple selections allowed',
      '-e',
      'set outputLines to {}',
      '-e',
      'repeat with selectedFile in selectedFiles',
      '-e',
      'copy POSIX path of selectedFile to end of outputLines',
      '-e',
      'end repeat',
      '-e',
      'return outputLines as string',
    ]);
    return _normalizeSelection(result, separator: ', ');
  }

  Future<List<String>> _pickOnLinux() async {
    final result = await Process.run('zenity', <String>[
      '--file-selection',
      '--multiple',
      '--separator=\n',
      '--title=选择会话附件',
    ]);
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
}
