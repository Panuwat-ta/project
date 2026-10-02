import 'dart:async';
import 'package:scam_image_mobile/features/auth/data/models/auth_token_model.dart';
import 'package:scam_image_mobile/features/auth/data/models/user_model.dart';
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
  test('login finishing after logout cannot save credentials', () async {
    final remote = MockAuthRemote();
    final local = MockAuthLocal();
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
    final pending = Completer<(UserModel, AuthTokenModel)>();
    when(
      () => remote.login(email: 'user@example.com', password: 'password'),
    ).thenAnswer((_) => pending.future);
    when(() => remote.logout()).thenAnswer((_) async {});
    when(() => local.clearTokens()).thenAnswer((_) async {});
    final login = repository.login(
      email: 'user@example.com',
      password: 'password',
    );
    final rejected = expectLater(login, throwsA(isA<AuthException>()));
    await Future<void>.delayed(Duration.zero);
    await repository.logout();
    pending.complete((
      const UserModel(id: '1', email: 'user@example.com', displayName: 'User'),
      const AuthTokenModel(accessToken: 'stale', refreshToken: 'stale-refresh'),
    ));
    await rejected;
    verify(() => local.clearTokens()).called(2);
  });
}
