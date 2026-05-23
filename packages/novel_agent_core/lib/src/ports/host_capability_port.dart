import '../common/host_capability.dart';
import '../common/host_platform.dart';

abstract class HostCapabilityPort {
  Future<HostPlatform> detectPlatform();

  Future<bool> supports(HostCapability capability);
}
