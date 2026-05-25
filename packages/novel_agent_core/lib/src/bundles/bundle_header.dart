class BundleHeader {
  const BundleHeader({
    required this.bundleKind,
    required this.schemaVersion,
    required this.bundleVersion,
    required this.title,
    this.description = '',
    this.createdAt = '',
    this.checksum = '',
  });

  final String bundleKind;
  final int schemaVersion;
  final String bundleVersion;
  final String title;
  final String description;
  final String createdAt;
  final String checksum;
}
