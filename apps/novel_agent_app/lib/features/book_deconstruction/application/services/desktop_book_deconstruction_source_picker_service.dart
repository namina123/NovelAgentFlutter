import '../../../../shared/services/desktop_text_file_picker_service.dart';

class DesktopBookDeconstructionSourcePickerService {
  const DesktopBookDeconstructionSourcePickerService();

  Future<String?> pickSourceFile() async {
    // 中文注释: 拆书源文件选择保持在宿主边界，避免页面层直接依赖平台命令或绝对路径细节。
    return const DesktopTextFilePickerService().pickSingleFile(
      dialogTitle: '选择拆书源文件',
    );
  }
}
