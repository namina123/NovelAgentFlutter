import '../common/json_types.dart';
import '../project/project_descriptor.dart';

abstract class ToolExecutionPort {
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  });
}
