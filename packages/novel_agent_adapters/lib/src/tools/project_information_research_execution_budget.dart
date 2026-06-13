class ProjectInformationResearchExecutionBudget {
  const ProjectInformationResearchExecutionBudget({
    this.allowGatewayExecution = false,
    this.searchLimit = 3,
    this.fetchMaxChars = 1200,
  });

  final bool allowGatewayExecution;
  final int searchLimit;
  final int fetchMaxChars;
}
