class InspirationWorkbenchLongTaskLaunchViewData {
  const InspirationWorkbenchLongTaskLaunchViewData({
    required this.isVisible,
    required this.canLaunch,
    required this.title,
    required this.description,
    required this.guidancePath,
    required this.actionLabel,
  });

  final bool isVisible;
  final bool canLaunch;
  final String title;
  final String description;
  final String guidancePath;
  final String actionLabel;

  factory InspirationWorkbenchLongTaskLaunchViewData.hidden() {
    return const InspirationWorkbenchLongTaskLaunchViewData(
      isVisible: false,
      canLaunch: false,
      title: '',
      description: '',
      guidancePath: '',
      actionLabel: '',
    );
  }
}
