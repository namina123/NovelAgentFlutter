import 'bundle_validation_issue.dart';

class BundleValidationResult {
  const BundleValidationResult({
    required this.ok,
    this.issues = const <BundleValidationIssue>[],
  });

  final bool ok;
  final List<BundleValidationIssue> issues;
}
