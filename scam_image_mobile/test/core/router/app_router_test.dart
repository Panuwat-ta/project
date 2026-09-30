import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/router/app_router.dart';
import 'package:scam_image_mobile/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  test('splash and onboarding are always reachable', () async {
    expect(await AppRouter.guardPath(repo, '/splash'), isNull);
    expect(await AppRouter.guardPath(repo, '/onboarding'), isNull);
    verifyNever(() => repo.hasSeenOnboarding());
  });

  test('protected deep link redirects to onboarding before consent', () async {
    when(() => repo.hasSeenOnboarding()).thenAnswer((_) async => false);
    expect(await AppRouter.guardPath(repo, '/result/scan-1'), '/onboarding');
    verifyNever(() => repo.hasValidToken());
  });

  test(
    'login/register remain reachable after onboarding without token',
    () async {
      when(() => repo.hasSeenOnboarding()).thenAnswer((_) async => true);
      expect(await AppRouter.guardPath(repo, '/login'), isNull);
      expect(await AppRouter.guardPath(repo, '/register'), isNull);
      verifyNever(() => repo.hasValidToken());
    },
  );

  test('protected deep link redirects unauthenticated user to login', () async {
    when(() => repo.hasSeenOnboarding()).thenAnswer((_) async => true);
    when(() => repo.hasValidToken()).thenAnswer((_) async => false);
    expect(await AppRouter.guardPath(repo, '/main/history'), '/login');
  });

  test(
    'protected route is allowed with onboarding and a valid session',
    () async {
      when(() => repo.hasSeenOnboarding()).thenAnswer((_) async => true);
      when(() => repo.hasValidToken()).thenAnswer((_) async => true);
      expect(await AppRouter.guardPath(repo, '/notifications'), isNull);
    },
  );

  test('storage failure fails closed for protected route', () async {
    when(() => repo.hasSeenOnboarding()).thenThrow(Exception('storage failed'));
    expect(await AppRouter.guardPath(repo, '/main/home'), '/login');
  });
}
