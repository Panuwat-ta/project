import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:scam_image_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:scam_image_mobile/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemote extends Mock implements AuthRemoteDataSource {}
class MockAuthLocal extends Mock implements AuthLocalDataSource {}

void main() {
  test('logout clears local auth even when server is unreachable', () async {
    final remote = MockAuthRemote();
    final local = MockAuthLocal();
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
    when(() => remote.logout()).thenThrow(const NetworkException('offline'));
    when(() => local.clearTokens()).thenAnswer((_) async {});

    await expectLater(repository.logout(), completes);

    verify(() => remote.logout()).called(1);
    verify(() => local.clearTokens()).called(1);
  });
}
