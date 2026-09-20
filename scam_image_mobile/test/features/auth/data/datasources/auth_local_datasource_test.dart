import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/storage/secure_storage.dart';
import 'package:scam_image_mobile/features/auth/data/datasources/auth_local_datasource.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  test('clearTokens removes auth credentials without deleting all storage', () async {
    final storage = MockSecureStorage();
    final dataSource = AuthLocalDataSource(secureStorage: storage);
    when(() => storage.clearAuthTokens()).thenAnswer((_) async {});

    await dataSource.clearTokens();

    verify(() => storage.clearAuthTokens()).called(1);
    verifyNever(() => storage.deleteAll());
  });
}
