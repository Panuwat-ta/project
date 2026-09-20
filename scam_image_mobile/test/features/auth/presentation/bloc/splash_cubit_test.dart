import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/auth/domain/entities/user.dart';
import 'package:scam_image_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:scam_image_mobile/features/auth/presentation/bloc/splash_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const user = User(id: '1', email: 'user@example.com', displayName: 'User');

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  SplashCubit build() => SplashCubit(repo, splashDelay: Duration.zero);

  blocTest<SplashCubit, SplashState>(
    'requires onboarding before reading auth tokens',
    build: () {
      when(() => repo.hasSeenOnboarding()).thenAnswer((_) async => false);
      return build();
    },
    act: (cubit) => cubit.checkSession(),
    expect: () => const [CheckingSession(), SplashConsentRequired()],
    verify: (_) => verifyNever(() => repo.hasValidToken()),
  );

  blocTest<SplashCubit, SplashState>(
    'routes to unauthenticated when there is no access token',
    build: () {
      when(() => repo.hasSeenOnboarding()).thenAnswer((_) async => true);
      when(() => repo.hasValidToken()).thenAnswer((_) async => false);
      return build();
    },
    act: (cubit) => cubit.checkSession(),
    expect: () => const [CheckingSession(), SplashUnauthenticated()],
    verify: (_) => verifyNever(() => repo.getCurrentUser()),
  );

  blocTest<SplashCubit, SplashState>(
    'restores authenticated user for a valid session',
    build: () {
      when(() => repo.hasSeenOnboarding()).thenAnswer((_) async => true);
      when(() => repo.hasValidToken()).thenAnswer((_) async => true);
      when(() => repo.getCurrentUser()).thenAnswer((_) async => user);
      return build();
    },
    act: (cubit) => cubit.checkSession(),
    expect: () => const [CheckingSession(), SplashAuthenticated(user: user)],
  );

  blocTest<SplashCubit, SplashState>(
    'treats a missing current user as unauthenticated',
    build: () {
      when(() => repo.hasSeenOnboarding()).thenAnswer((_) async => true);
      when(() => repo.hasValidToken()).thenAnswer((_) async => true);
      when(() => repo.getCurrentUser()).thenAnswer((_) async => null);
      return build();
    },
    act: (cubit) => cubit.checkSession(),
    expect: () => const [CheckingSession(), SplashUnauthenticated()],
  );

  blocTest<SplashCubit, SplashState>(
    'emits failure when session storage or profile lookup throws',
    build: () {
      when(
        () => repo.hasSeenOnboarding(),
      ).thenThrow(Exception('storage failed'));
      return build();
    },
    act: (cubit) => cubit.checkSession(),
    expect: () => [
      const CheckingSession(),
      isA<SplashFailure>().having(
        (s) => s.message,
        'message',
        contains('storage failed'),
      ),
    ],
  );
}
