import 'dart:io';

class DesktopBookDeconstructionSourcePickerService {
  const DesktopBookDeconstructionSourcePickerService();

  Future<String?> pickSourceFile() async {
    // 中文注释: 拆书源文件选择保持在宿主边界，避免页面层直接依赖平台命令或绝对路径细节。
    if (Platform.isWindows) {
      return _pickOnWindows();
    }
    if (Platform.isMacOS) {
      return _pickOnMacOs();
    }
    if (Platform.isLinux) {
      return _pickOnLinux();
    }
    return null;
  }

  Future<String?> _pickOnWindows() async {
    final result = await Process.run('powershell', <String>[
      '-NoProfile',
      '-STA',
      '-Command',
      r'''
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title = "选择拆书源文件"
$dialog.Filter = "文本与 Markdown|*.txt;*.md;*.markdown|所有文件|*.*"
if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::Out.Write($dialog.FileName)
}
''',
    ]);
    return _normalizeSelection(result);
  }

  Future<String?> _pickOnMacOs() async {
    final result = await Process.run('osascript', <String>[
      '-e',
      'POSIX path of (choose file with prompt "选择拆书源文件")',
    ]);
    return _normalizeSelection(result);
  }

  Future<String?> _pickOnLinux() async {
    final result = await Process.run('zenity', <String>[
      '--file-selection',
      '--title=选择拆书源文件',
    ]);
    return _normalizeSelection(result);
  }

  String? _normalizeSelection(ProcessResult result) {
    if (result.exitCode != 0) {
      return null;
    }
    final output = result.stdout?.toString().trim() ?? '';
    return output.isEmpty ? null : output;
  }
}
