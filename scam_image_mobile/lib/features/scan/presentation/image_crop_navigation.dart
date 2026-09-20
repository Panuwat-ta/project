Map<String, dynamic> buildAnalysisNavigationExtra({
  required String filePath,
  required String scanName,
}) {
  final trimmedName = scanName.trim();
  return <String, dynamic>{
    'filePath': filePath,
    if (trimmedName.isNotEmpty) 'scanName': trimmedName,
  };
}
