import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/network/api_endpoints.dart';
import 'package:scam_image_mobile/features/settings/data/datasources/settings_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('deleteAccount uses DELETE /users/me with password body', () async {
    final dio = MockDio();
    final dataSource = SettingsRemoteDataSourceImpl(dio: dio);
    when(
      () => dio.delete<void>(
        ApiEndpoints.usersMe,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<void>(
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiEndpoints.usersMe),
      ),
    );

    await dataSource.deleteAccount('secret123');

    final captured = verify(
      () => dio.delete<void>(
        ApiEndpoints.usersMe,
        data: captureAny(named: 'data'),
      ),
    ).captured.single as Map<String, dynamic>;
    expect(captured, {'password': 'secret123'});
  });
}
