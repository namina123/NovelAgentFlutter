class SettingsSearchOption<T> {
  const SettingsSearchOption({
    required this.value,
    required this.label,
    this.note = '',
  });

  final T value;
  final String label;
  final String note;
}
