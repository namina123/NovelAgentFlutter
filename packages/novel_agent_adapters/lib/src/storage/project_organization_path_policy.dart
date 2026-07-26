class ProjectOrganizationPathPolicy {
  const ProjectOrganizationPathPolicy();

  String profilePath(String organizationId) =>
      'assets/organizations/$organizationId.md';

  String legacyProfilePath(String displayName) =>
      'organizations/$displayName.md';
}
