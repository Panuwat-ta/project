import 'dart:async';
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

  test(
    'default startup checks storage without an artificial splash delay',
    () async {
      final pending = Completer<bool>();
      when(() => repo.hasSeenOnboarding()).thenAnswer((_) => pending.future);
      final cubit = SplashCubit(repo);
      addTearDown(cubit.close);
      expect(cubit.splashDelay, Duration.zero);
      final checking = cubit.checkSession();
      await Future<void>.delayed(Duration.zero);
      verify(() => repo.hasSeenOnboarding()).called(1);
      pending.complete(false);
      await checking;
      expect(cubit.state, const SplashConsentRequired());
    },
  );

  test('concurrent session checks share one storage lookup', () async {
    final pending = Completer<bool>();
    when(() => repo.hasSeenOnboarding()).thenAnswer((_) => pending.future);
    final cubit = SplashCubit(repo, splashDelay: Duration.zero);
    final first = cubit.checkSession();
    final second = cubit.checkSession();
    await Future<void>.delayed(Duration.zero);
    pending.complete(false);
    await Future.wait([first, second]);
    verify(() => repo.hasSeenOnboarding()).called(1);
    await cubit.close();
  });

  for (final stage in ['onboarding', 'token', 'profile']) {
    test('closing during $stage lookup ignores the late response', () async {
      final pendingBool = Completer<bool>();
      final pendingUser = Completer<User?>();
      when(() => repo.hasSeenOnboarding()).thenAnswer(
        (_) => stage == 'onboarding' ? pendingBool.future : Future.value(true),
      );
      when(() => repo.hasValidToken()).thenAnswer(
        (_) => stage == 'token' ? pendingBool.future : Future.value(true),
      );
      when(() => repo.getCurrentUser()).thenAnswer((_) => pendingUser.future);
      final cubit = SplashCubit(repo, splashDelay: Duration.zero);
      final checking = cubit.checkSession();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      if (stage == 'profile') {
        pendingUser.complete(user);
      } else {
        pendingBool.complete(true);
      }
      if (!pendingUser.isCompleted) pendingUser.complete(user);
      await expectLater(
        checking.timeout(const Duration(seconds: 1)),
        completes,
      );
      expect(cubit.state, const CheckingSession());
    });
  }

  test(
    'closing during an explicitly requested delay does not read storage',
    () async {
      final cubit = SplashCubit(
        repo,
        splashDelay: const Duration(milliseconds: 10),
      );
      final checking = cubit.checkSession();
      await cubit.close();
      await checking;
      verifyNever(() => repo.hasSeenOnboarding());
      verifyNever(() => repo.hasValidToken());
      verifyNever(() => repo.getCurrentUser());
    },
  );

  test('closed cubit does not start another session lookup', () async {
    final cubit = SplashCubit(repo);
    await cubit.close();
    await cubit.checkSession();
    verifyNever(() => repo.hasSeenOnboarding());
    verifyNever(() => repo.hasValidToken());
    verifyNever(() => repo.getCurrentUser());
  });

  test(
    'closing during a failed lookup does not emit a failure after close',
    () async {
      final pending = Completer<bool>();
      when(() => repo.hasSeenOnboarding()).thenAnswer((_) => pending.future);
      final cubit = SplashCubit(repo);
      final checking = cubit.checkSession();
      await cubit.close();
      pending.completeError(Exception('late storage error'));
      await expectLater(checking, completes);
    },
  );

  test('a failed session lookup can be retried', () async {
    var calls = 0;
    when(() => repo.hasSeenOnboarding()).thenAnswer((_) async {
      if (++calls == 1) throw Exception('temporary storage failure');
      return false;
    });
    final cubit = SplashCubit(repo);
    await cubit.checkSession();
    expect(cubit.state, isA<SplashFailure>());
    await cubit.checkSession();
    expect(cubit.state, const SplashConsentRequired());
    expect(calls, 2);
    await cubit.close();
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
