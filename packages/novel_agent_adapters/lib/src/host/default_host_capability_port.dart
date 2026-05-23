import 'package:novel_agent_core/novel_agent_core.dart';

class DefaultHostCapabilityPort implements HostCapabilityPort {
  @override
  Future<HostPlatform> detectPlatform() {
    // 中文注释: 这里未来负责平台探测，避免在上层功能里散落平台分支。
    throw UnimplementedError('待实现平台探测。');
  }

  @override
  Future<bool> supports(HostCapability capability) {
    // 中文注释: 这里未来负责能力探测，desktop-only 能力必须通过这里显式暴露。
    throw UnimplementedError('待实现能力探测。');
  }
}
