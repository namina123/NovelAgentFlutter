import '../common/json_types.dart';

abstract class ProviderCapabilityPort {
  JsonMap resolve(
    JsonMap credential,
    JsonMap modelProfile, {
    JsonMap runtimeProfile = const <String, Object?>{},
  });
}
