String buildReportDescription({
  required String category,
  required String customCategory,
  required String details,
}) {
  final trimmedDetails = details.trim();
  final trimmedCustomCategory = customCategory.trim();
  if (category == 'other' && trimmedCustomCategory.isNotEmpty) {
    return '[$trimmedCustomCategory] $trimmedDetails';
  }
  return trimmedDetails;
}

String? resolveReportPlatform({
  required String? selectedPlatform,
  required String customPlatform,
}) {
  final value = selectedPlatform == 'other'
      ? customPlatform.trim()
      : selectedPlatform?.trim();
  return value == null || value.isEmpty ? null : value;
}
