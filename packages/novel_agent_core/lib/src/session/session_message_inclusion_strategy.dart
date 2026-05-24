import '../common/json_types.dart';

abstract class SessionMessageInclusionStrategy {
  bool includeInContext({
    required String role,
    String outcome = 'success',
    JsonMap metadata = const <String, Object?>{},
  });
}
