import 'package:equatable/equatable.dart';

class ScanImage extends Equatable {
  final String filePath;
  final int fileSizeBytes;
  final String format; // 'jpg', 'jpeg', 'png', 'webp'

  const ScanImage({
    required this.filePath,
    required this.fileSizeBytes,
    required this.format,
  });

  bool get isValidFormat =>
      ['jpg', 'jpeg', 'png', 'webp'].contains(format.toLowerCase());

  bool get isValidSize => fileSizeBytes <= 10 * 1024 * 1024; // 10 MB

  @override
  List<Object?> get props => [filePath, fileSizeBytes, format];
}
