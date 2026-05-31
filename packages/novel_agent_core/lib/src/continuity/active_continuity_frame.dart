import 'continuity_frame.dart';

class ActiveContinuityFrame {
  const ActiveContinuityFrame({
    this.frame,
    this.frameChain = const <ContinuityFrame>[],
  });

  final ContinuityFrame? frame;
  final List<ContinuityFrame> frameChain;

  bool get hasParent {
    return frame != null && frame!.parentFrameId.isNotEmpty;
  }
}
