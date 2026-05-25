import 'dart:io';

class DesktopProjectDirectoryPickerService {
  const DesktopProjectDirectoryPickerService();

  Future<String?> pickProjectDirectory() async {
    // 中文注释: 桌面端目录选择统一走系统原生命令，避免为单一能力额外引入 Flutter 插件依赖。
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
$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
$dialog.Description = "选择已有项目目录"
$dialog.ShowNewFolderButton = $false
if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::Out.Write($dialog.SelectedPath)
}
''',
    ]);
    return _normalizedPath(result);
  }

  Future<String?> _pickOnMacOs() async {
    final result = await Process.run('osascript', <String>[
      '-e',
      'POSIX path of (choose folder with prompt "选择已有项目目录")',
    ]);
    return _normalizedPath(result);
  }

  Future<String?> _pickOnLinux() async {
    final result = await Process.run('zenity', <String>[
      '--file-selection',
      '--directory',
      '--title=选择已有项目目录',
    ]);
    return _normalizedPath(result);
  }

  String? _normalizedPath(ProcessResult result) {
    // 中文注释: 目录选择结果统一在这里裁剪；取消选择或命令失败时返回 null。
    if (result.exitCode != 0) {
      return null;
    }
    final output = result.stdout?.toString().trim() ?? '';
    if (output.isEmpty) {
      return null;
    }
    return output;
  }
}
