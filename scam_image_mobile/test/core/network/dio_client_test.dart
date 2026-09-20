import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/network/dio_client.dart';
import 'package:scam_image_mobile/core/storage/secure_storage.dart';

class MemorySecureStorage extends SecureStorage {
  final Map<String, String> values = <String, String>{};
  int clearCount = 0;

  @override
  Future<String?> getToken(String key) async => values[key];

  @override
  Future<void> saveToken(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> deleteToken(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clearAuthTokens() async {
    clearCount += 1;
    values.remove(kAccessToken);
    values.remove(kRefreshToken);
    values.remove(kTokenExpiresAt);
  }
}

Future<void> _writeJson(
  HttpRequest request,
  int statusCode,
  Object body,
) async {
  request.response.statusCode = statusCode;
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(body));
  await request.response.close();
}

String _baseUrl(HttpServer server) =>
    'http://${server.address.host}:${server.port}';

void main() {
  test('network logging never exposes Authorization tokens', () async {
    final storage = MemorySecureStorage()
      ..values[kAccessToken] = 'sensitive-access-token';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final logs = <String>[];

    server.listen((request) async {
      await request.drain<void>();
      await _writeJson(request, HttpStatus.ok, {'ok': true});
    });

    await runZoned(
      () async {
        final dio = DioClient.createDio(
          secureStorage: storage,
          baseUrl: _baseUrl(server),
        );
        await dio.get<Map<String, dynamic>>('/protected');
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => logs.add(line),
      ),
    );

    final output = logs.join('\n');
    expect(output, isNot(contains('sensitive-access-token')));
    expect(output, isNot(contains('Authorization: Bearer')));
    await server.close(force: true);
  });

  test('FormData request is sent as multipart/form-data, not JSON', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requestFuture = server.first;
    final dio = DioClient.createDio(
      secureStorage: MemorySecureStorage(),
      baseUrl: _baseUrl(server),
    );

    final responseFuture = dio.post<void>(
      '/upload',
      data: FormData.fromMap({'name': 'sample'}),
    );
    final request = await requestFuture;
    final contentType = request.headers.contentType;
    await request.drain<void>();
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    await responseFuture;
    await server.close(force: true);

    expect(contentType?.mimeType, 'multipart/form-data');
  });

  test(
    'public login never sends stale Bearer token and 401 does not refresh',
    () async {
      final storage = MemorySecureStorage()
        ..values[kAccessToken] = 'old-access'
        ..values[kRefreshToken] = 'old-refresh';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? loginAuthorization;
      var refreshCount = 0;

      server.listen((request) async {
        if (request.uri.path == '/auth/login') {
          loginAuthorization = request.headers.value(
            HttpHeaders.authorizationHeader,
          );
          await request.drain<void>();
          await _writeJson(request, HttpStatus.unauthorized, {
            'detail': 'Incorrect email or password',
          });
        } else if (request.uri.path == '/auth/refresh') {
          refreshCount += 1;
          await request.drain<void>();
          await _writeJson(request, HttpStatus.ok, {
            'access_token': 'unexpected',
            'refresh_token': 'unexpected',
          });
        }
      });

      final dio = DioClient.createDio(
        secureStorage: storage,
        baseUrl: _baseUrl(server),
      );
      await expectLater(
        dio.post<void>(
          '/auth/login',
          data: {'username': 'x', 'password': 'bad'},
        ),
        throwsA(isA<DioException>()),
      );

      expect(loginAuthorization, isNull);
      expect(refreshCount, 0);
      expect(storage.values[kAccessToken], 'old-access');
      await server.close(force: true);
    },
  );

  test(
    'protected 401 refreshes once, stores tokens and retries with new token',
    () async {
      final storage = MemorySecureStorage()
        ..values[kAccessToken] = 'old-access'
        ..values[kRefreshToken] = 'old-refresh';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var protectedCount = 0;
      var refreshCount = 0;

      server.listen((request) async {
        if (request.uri.path == '/protected') {
          protectedCount += 1;
          final auth = request.headers.value(HttpHeaders.authorizationHeader);
          if (auth == 'Bearer new-access') {
            await _writeJson(request, HttpStatus.ok, {'ok': true});
          } else {
            await _writeJson(request, HttpStatus.unauthorized, {
              'detail': 'expired',
            });
          }
        } else if (request.uri.path == '/auth/refresh') {
          refreshCount += 1;
          await request.drain<void>();
          await _writeJson(request, HttpStatus.ok, {
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          });
        }
      });

      final dio = DioClient.createDio(
        secureStorage: storage,
        baseUrl: _baseUrl(server),
      );
      final response = await dio.get<Map<String, dynamic>>('/protected');

      expect(response.data?['ok'], isTrue);
      expect(protectedCount, 2);
      expect(refreshCount, 1);
      expect(storage.values[kAccessToken], 'new-access');
      expect(storage.values[kRefreshToken], 'new-refresh');
      await server.close(force: true);
    },
  );

  test(
    'concurrent protected 401 responses share one refresh request',
    () async {
      final storage = MemorySecureStorage()
        ..values[kAccessToken] = 'old-access'
        ..values[kRefreshToken] = 'old-refresh';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var refreshCount = 0;

      server.listen((request) async {
        if (request.uri.path == '/auth/refresh') {
          refreshCount += 1;
          await request.drain<void>();
          await Future<void>.delayed(const Duration(milliseconds: 80));
          await _writeJson(request, HttpStatus.ok, {
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          });
          return;
        }

        final auth = request.headers.value(HttpHeaders.authorizationHeader);
        if (auth == 'Bearer new-access') {
          await _writeJson(request, HttpStatus.ok, {'path': request.uri.path});
        } else {
          await _writeJson(request, HttpStatus.unauthorized, {
            'detail': 'expired',
          });
        }
      });

      final dio = DioClient.createDio(
        secureStorage: storage,
        baseUrl: _baseUrl(server),
      );
      final responses = await Future.wait([
        dio.get<Map<String, dynamic>>('/one'),
        dio.get<Map<String, dynamic>>('/two'),
      ]);

      expect(responses.map((r) => r.statusCode), everyElement(HttpStatus.ok));
      expect(refreshCount, 1);
      await server.close(force: true);
    },
  );

  test(
    'multipart request can be retried after refresh without finalized FormData error',
    () async {
      final storage = MemorySecureStorage()
        ..values[kAccessToken] = 'old-access'
        ..values[kRefreshToken] = 'old-refresh';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final uploadBodies = <String>[];
      var uploadCount = 0;

      server.listen((request) async {
        if (request.uri.path == '/auth/refresh') {
          await request.drain<void>();
          await _writeJson(request, HttpStatus.ok, {
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          });
          return;
        }
        if (request.uri.path == '/upload') {
          uploadCount += 1;
          uploadBodies.add(await utf8.decoder.bind(request).join());
          final auth = request.headers.value(HttpHeaders.authorizationHeader);
          if (auth == 'Bearer new-access') {
            await _writeJson(request, HttpStatus.ok, {'ok': true});
          } else {
            await _writeJson(request, HttpStatus.unauthorized, {
              'detail': 'expired',
            });
          }
        }
      });

      final dio = DioClient.createDio(
        secureStorage: storage,
        baseUrl: _baseUrl(server),
      );
      final response = await dio.post<Map<String, dynamic>>(
        '/upload',
        data: FormData.fromMap({'name': 'sample'}),
      );

      expect(response.data?['ok'], isTrue);
      expect(uploadCount, 2);
      expect(uploadBodies, hasLength(2));
      expect(uploadBodies[1], contains('sample'));
      await server.close(force: true);
    },
  );

  test(
    'refresh failure clears local auth tokens and preserves original 401',
    () async {
      final storage = MemorySecureStorage()
        ..values[kAccessToken] = 'old-access'
        ..values[kRefreshToken] = 'bad-refresh';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      server.listen((request) async {
        if (request.uri.path == '/auth/refresh') {
          await request.drain<void>();
          await _writeJson(request, HttpStatus.unauthorized, {
            'detail': 'bad refresh',
          });
        } else {
          await _writeJson(request, HttpStatus.unauthorized, {
            'detail': 'expired',
          });
        }
      });

      final dio = DioClient.createDio(
        secureStorage: storage,
        baseUrl: _baseUrl(server),
      );
      await expectLater(
        dio.get<void>('/protected'),
        throwsA(isA<DioException>()),
      );

      expect(storage.values[kAccessToken], isNull);
      expect(storage.values[kRefreshToken], isNull);
      expect(storage.clearCount, greaterThanOrEqualTo(1));
      await server.close(force: true);
    },
  );

  test(
    'protected request without access token is sent without Authorization',
    () async {
      final storage = MemorySecureStorage();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? authorization;
      server.listen((request) async {
        authorization = request.headers.value(HttpHeaders.authorizationHeader);
        await request.drain<void>();
        await _writeJson(request, HttpStatus.ok, {'ok': true});
      });

      final dio = DioClient.createDio(
        secureStorage: storage,
        baseUrl: _baseUrl(server),
      );
      final response = await dio.get<Map<String, dynamic>>('/protected');

      expect(response.data?['ok'], isTrue);
      expect(authorization, isNull);
      await server.close(force: true);
    },
  );

  test('non-401 response error does not refresh or clear tokens', () async {
    final storage = MemorySecureStorage()
      ..values[kAccessToken] = 'old-access'
      ..values[kRefreshToken] = 'old-refresh';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var refreshCount = 0;
    server.listen((request) async {
      if (request.uri.path == '/auth/refresh') refreshCount += 1;
      await request.drain<void>();
      await _writeJson(request, HttpStatus.internalServerError, {
        'detail': 'boom',
      });
    });

    final dio = DioClient.createDio(
      secureStorage: storage,
      baseUrl: _baseUrl(server),
    );
    await expectLater(
      dio.get<void>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(refreshCount, 0);
    expect(storage.clearCount, 0);
    expect(storage.values[kAccessToken], 'old-access');
    await server.close(force: true);
  });

  test('protected 401 without refresh token clears local auth', () async {
    final storage = MemorySecureStorage()..values[kAccessToken] = 'old-access';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await request.drain<void>();
      await _writeJson(request, HttpStatus.unauthorized, {'detail': 'expired'});
    });

    final dio = DioClient.createDio(
      secureStorage: storage,
      baseUrl: _baseUrl(server),
    );
    await expectLater(
      dio.get<void>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(storage.clearCount, 1);
    expect(storage.values[kAccessToken], isNull);
    await server.close(force: true);
  });

  test(
    '401 from refresh endpoint clears tokens without recursive refresh',
    () async {
      final storage = MemorySecureStorage()
        ..values[kAccessToken] = 'old-access'
        ..values[kRefreshToken] = 'old-refresh';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requestCount = 0;
      server.listen((request) async {
        requestCount += 1;
        await request.drain<void>();
        await _writeJson(request, HttpStatus.unauthorized, {
          'detail': 'invalid',
        });
      });

      final dio = DioClient.createDio(
        secureStorage: storage,
        baseUrl: _baseUrl(server),
      );
      await expectLater(
        dio.post<void>('/auth/refresh', data: {'refresh_token': 'old-refresh'}),
        throwsA(isA<DioException>()),
      );

      expect(requestCount, 1);
      expect(storage.clearCount, 1);
      expect(storage.values[kAccessToken], isNull);
      expect(storage.values[kRefreshToken], isNull);
      await server.close(force: true);
    },
  );

  test(
    'incomplete refresh payload clears tokens and preserves original 401',
    () async {
      final storage = MemorySecureStorage()
        ..values[kAccessToken] = 'old-access'
        ..values[kRefreshToken] = 'old-refresh';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        await request.drain<void>();
        if (request.uri.path == '/auth/refresh') {
          await _writeJson(request, HttpStatus.ok, {
            'access_token': 'new-access',
          });
        } else {
          await _writeJson(request, HttpStatus.unauthorized, {
            'detail': 'expired',
          });
        }
      });

      final dio = DioClient.createDio(
        secureStorage: storage,
        baseUrl: _baseUrl(server),
      );
      await expectLater(
        dio.get<void>('/protected'),
        throwsA(isA<DioException>()),
      );

      expect(storage.clearCount, 1);
      expect(storage.values[kAccessToken], isNull);
      expect(storage.values[kRefreshToken], isNull);
      await server.close(force: true);
    },
  );

  test('camelCase refresh payload is accepted', () async {
    final storage = MemorySecureStorage()
      ..values[kAccessToken] = 'old-access'
      ..values[kRefreshToken] = 'old-refresh';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await request.drain<void>();
      if (request.uri.path == '/auth/refresh') {
        await _writeJson(request, HttpStatus.ok, {
          'accessToken': 'camel-access',
          'refreshToken': 'camel-refresh',
        });
      } else if (request.headers.value(HttpHeaders.authorizationHeader) ==
          'Bearer camel-access') {
        await _writeJson(request, HttpStatus.ok, {'ok': true});
      } else {
        await _writeJson(request, HttpStatus.unauthorized, {
          'detail': 'expired',
        });
      }
    });

    final dio = DioClient.createDio(
      secureStorage: storage,
      baseUrl: _baseUrl(server),
    );
    final response = await dio.get<Map<String, dynamic>>('/protected');

    expect(response.data?['ok'], isTrue);
    expect(storage.values[kAccessToken], 'camel-access');
    expect(storage.values[kRefreshToken], 'camel-refresh');
    await server.close(force: true);
  });
}
