import '../../../../shared/services/desktop_text_file_picker_service.dart';

class DesktopProjectImportFilePickerService {
  const DesktopProjectImportFilePickerService();

  Future<List<String>> pickFiles() async {
    return const DesktopTextFilePickerService().pickFiles(
      dialogTitle: '选择要导入的文件',
      allowMultiple: true,
    );
  }
}
