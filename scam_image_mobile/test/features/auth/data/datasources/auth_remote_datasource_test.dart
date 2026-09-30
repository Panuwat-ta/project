import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/network/api_endpoints.dart';
import 'package:scam_image_mobile/features/auth/data/datasources/auth_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> _response(Map<String, dynamic> data) =>
    Response<Map<String, dynamic>>(
      data: data,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/'),
    );

void main() {
  late MockDio dio;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = AuthRemoteDataSourceImpl(dio: dio);
  });

  test('register follows UserResponse with login to obtain tokens', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => _response({
        'id': 7,
        'email': 'user@example.com',
        'full_name': 'User',
        'role': 'user',
      }),
    );
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => _response({
        'access_token': 'access',
        'refresh_token': 'refresh',
        'user': {'id': 7, 'email': 'user@example.com', 'full_name': 'User'},
      }),
    );

    final (user, token) = await dataSource.register(
      email: 'user@example.com',
      password: 'secret123',
      displayName: 'User',
      systemConsent: true,
      researchConsent: true,
    );

    expect(user.id, '7');
    expect(token.accessToken, 'access');
    expect(token.refreshToken, 'refresh');
    final registerBody =
        verify(
              () => dio.post<Map<String, dynamic>>(
                ApiEndpoints.register,
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(registerBody['system_consent'], true);
    expect(registerBody['research_consent'], true);
    verify(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: any(named: 'data'),
      ),
    ).called(1);
  });
}
