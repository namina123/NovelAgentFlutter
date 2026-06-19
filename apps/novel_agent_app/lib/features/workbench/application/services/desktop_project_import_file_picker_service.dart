import '../../../../shared/services/desktop_text_file_picker_service.dart';
import 'desktop_project_directory_picker_service.dart';

class DesktopProjectImportFilePickerService {
  const DesktopProjectImportFilePickerService({
    DesktopProjectDirectoryPickerService? directoryPickerService,
  }) : _directoryPickerService =
           directoryPickerService ?? const DesktopProjectDirectoryPickerService();

  final DesktopProjectDirectoryPickerService _directoryPickerService;

  Future<List<String>> pickFiles() async {
    return const DesktopTextFilePickerService().pickFiles(
      dialogTitle: '选择要导入的文件',
      allowMultiple: true,
    );
  }

  Future<List<String>> pickDirectories() async {
    final selected = await _directoryPickerService.pickProjectDirectory();
    if (selected == null || selected.trim().isEmpty) {
      return const <String>[];
    }
    return <String>[selected.trim()];
  }
}
