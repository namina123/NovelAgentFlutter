import '../common/json_types.dart';
import '../context/context_assembler_service.dart';

class PrepareContextPackUseCase {
  PrepareContextPackUseCase({
    required ContextAssemblerService contextAssemblerService,
  }) : _contextAssemblerService = contextAssemblerService;

  final ContextAssemblerService _contextAssemblerService;

  JsonMap execute(JsonMap input) {
    // 中文注释: 这个用例给 GUI 和 CLI 提供统一入口，避免宿主层自己拼上下文包流程。
    return _contextAssemblerService.assemble(input);
  }
}
