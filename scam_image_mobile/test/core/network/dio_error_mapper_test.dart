import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/core/network/dio_error_mapper.dart';

void main() {
  test(
    'untrusted TLS certificate is an authoritative failure, not offline fallback',
    () {
      final error = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/history'),
          type: DioExceptionType.badCertificate,
        ),
      );
      expect(error, isA<ServerException>());
      expect(error, isNot(isA<NetworkException>()));
    },
  );
}
