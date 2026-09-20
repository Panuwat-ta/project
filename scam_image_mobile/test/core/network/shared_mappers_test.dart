import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/core/network/dio_error_mapper.dart';
import 'package:scam_image_mobile/core/network/url_resolver.dart';

DioException _dio(
  DioExceptionType type, {
  int? statusCode,
  dynamic data,
  String? message,
}) {
  return DioException(
    requestOptions: RequestOptions(path: '/x'),
    type: type,
    response: statusCode == null && data == null
        ? null
        : Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: statusCode,
            data: data,
          ),
    message: message,
  );
}

void main() {
  group('mapDioException', () {
    test('timeouts and connection errors map to NetworkException', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(mapDioException(_dio(t, message: 'm')), isA<NetworkException>());
      }
    });

    test('401/403 with message map to AuthException with server message', () {
      final e = mapDioException(
        _dio(
          DioExceptionType.badResponse,
          statusCode: 401,
          data: {'message': 'expired'},
        ),
      );
      expect(e, isA<AuthException>());
      expect('$e', contains('expired'));
    });

    test('401 without message maps to Unauthorised', () {
      final e = mapDioException(
        _dio(DioExceptionType.badResponse, statusCode: 401),
      );
      expect(e, isA<AuthException>());
    });

    test('detail key and String bodies are honored', () {
      final e1 = mapDioException(
        _dio(
          DioExceptionType.badResponse,
          statusCode: 500,
          data: {'detail': 'd1'},
        ),
      );
      expect(e1, isA<ServerException>());
      expect('$e1', contains('d1'));

      final e2 = mapDioException(
        _dio(DioExceptionType.badResponse, statusCode: 500, data: 'plain'),
      );
      expect('$e2', contains('plain'));
    });

    test(
      'FastAPI validation detail lists are converted without cast errors',
      () {
        final e = mapDioException(
          _dio(
            DioExceptionType.badResponse,
            statusCode: 422,
            data: {
              'detail': [
                {
                  'loc': ['body', 'password'],
                  'msg': 'Field required',
                  'type': 'missing',
                },
              ],
            },
          ),
        );

        expect(e, isA<ServerException>());
        expect('$e', contains('Field required'));
      },
    );

    test('other failures map to NetworkException', () {
      expect(
        mapDioException(_dio(DioExceptionType.cancel)),
        isA<NetworkException>(),
      );
    });
  });

  group('resolveUploadUrl', () {
    const base = 'http://10.0.0.1:8000/api/v1';

    test('null/empty stay null, absolute urls pass through', () {
      expect(resolveUploadUrl(base, null), isNull);
      expect(resolveUploadUrl(base, ''), isNull);
      expect(resolveUploadUrl(base, 'http://cdn/x.jpg'), 'http://cdn/x.jpg');
    });

    test('relative paths resolve against host with /uploads prefix', () {
      expect(
        resolveUploadUrl(base, 'uploads/a.jpg'),
        'http://10.0.0.1:8000/uploads/a.jpg',
      );
      expect(
        resolveUploadUrl(base, './uploads/a.jpg'),
        'http://10.0.0.1:8000/uploads/a.jpg',
      );
      expect(
        resolveUploadUrl(base, r'uploads\sub\a.jpg'),
        'http://10.0.0.1:8000/uploads/sub/a.jpg',
      );
    });

    test('missing baseUrl throws StateError', () {
      expect(() => resolveUploadUrl(null, 'a.jpg'), throwsStateError);
      expect(() => resolveUploadUrl('  ', 'a.jpg'), throwsStateError);
    });
  });
}
