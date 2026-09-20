import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/network/dio_client.dart';
import 'package:scam_image_mobile/core/storage/secure_storage.dart';

class FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getToken(String key) async => null;

  @override
  Future<void> clearAuthTokens() async {}
}

void main() {
  test('FormData request is sent as multipart/form-data, not JSON', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requestFuture = server.first;
    final dio = DioClient.createDio(
      secureStorage: FakeSecureStorage(),
      baseUrl: 'http://${server.address.host}:${server.port}',
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
}
