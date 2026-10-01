import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/report/domain/entities/scam_report.dart';
import 'package:scam_image_mobile/features/report/domain/repositories/report_repository.dart';
import 'package:scam_image_mobile/features/report/presentation/bloc/report_bloc.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockReportRepository extends Mock implements ReportRepository {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const tReport = ScamReport(
  scanId: 'scan-1',
  category: 'fake_slip',
  description: 'This is a fake slip report with enough description',
  platform: 'Facebook',
  referenceUrl: 'http://example.com',
  allowResearchUse: true,
);

void main() {
  late MockReportRepository mockRepo;

  setUp(() {
    mockRepo = MockReportRepository();
  });

  setUpAll(() {
    registerFallbackValue(tReport);
  });

  group('ReportSubmitted', () {
    blocTest<ReportBloc, ReportState>(
      'emits [ReportSubmitting, ReportSuccess] on success',
      build: () {
        when(() => mockRepo.submitReport(any())).thenAnswer((_) async {});
        return ReportBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ReportSubmitted(tReport)),
      expect: () => const [ReportSubmitting(), ReportSuccess()],
      verify: (_) {
        verify(() => mockRepo.submitReport(tReport)).called(1);
      },
    );

    blocTest<ReportBloc, ReportState>(
      'emits [ReportSubmitting, ReportError] with network message on NetworkException',
      build: () {
        when(
          () => mockRepo.submitReport(any()),
        ).thenThrow(const NetworkException('Connection error'));
        return ReportBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ReportSubmitted(tReport)),
      expect: () => [
        const ReportSubmitting(),
        isA<ReportError>().having(
          (s) => s.message,
          'message',
          equals('report_error_network'),
        ),
      ],
    );

    for (final message in ['Connection error', 'SocketException: closed']) {
      blocTest<ReportBloc, ReportState>(
        'maps $message to the network error state',
        build: () {
          when(
            () => mockRepo.submitReport(any()),
          ).thenThrow(Exception(message));
          return ReportBloc(repository: mockRepo);
        },
        act: (bloc) => bloc.add(const ReportSubmitted(tReport)),
        expect: () => const [
          ReportSubmitting(),
          ReportError('report_error_network'),
        ],
      );
    }

    blocTest<ReportBloc, ReportState>(
      'emits [ReportSubmitting, ReportError] with session message on AuthException',
      build: () {
        when(
          () => mockRepo.submitReport(any()),
        ).thenThrow(const AuthException('401'));
        return ReportBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ReportSubmitted(tReport)),
      expect: () => [
        const ReportSubmitting(),
        isA<ReportError>().having(
          (s) => s.message,
          'message',
          equals('report_error_auth'),
        ),
      ],
    );

    for (final message in ['403 forbidden']) {
      blocTest<ReportBloc, ReportState>(
        'maps $message to the auth error state',
        build: () {
          when(
            () => mockRepo.submitReport(any()),
          ).thenThrow(Exception(message));
          return ReportBloc(repository: mockRepo);
        },
        act: (bloc) => bloc.add(const ReportSubmitted(tReport)),
        expect: () => const [
          ReportSubmitting(),
          ReportError('report_error_auth'),
        ],
      );
    }

    blocTest<ReportBloc, ReportState>(
      'emits [ReportSubmitting, ReportError] with generic message on unknown error',
      build: () {
        when(
          () => mockRepo.submitReport(any()),
        ).thenThrow(Exception('unexpected'));
        return ReportBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ReportSubmitted(tReport)),
      expect: () => [
        const ReportSubmitting(),
        isA<ReportError>().having(
          (s) => s.message,
          'message',
          equals('report_error_generic'),
        ),
      ],
    );
  });

  test(
    'duplicate report while pending submits once and failure can retry',
    () async {
      final pending = Completer<void>();
      var calls = 0;
      when(() => mockRepo.submitReport(any())).thenAnswer((_) {
        calls++;
        return calls == 1 ? pending.future : Future<void>.value();
      });
      final bloc = ReportBloc(repository: mockRepo);
      bloc.add(const ReportSubmitted(tReport));
      await bloc.stream.firstWhere((state) => state is ReportSubmitting);
      bloc.add(const ReportSubmitted(tReport));
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      pending.completeError(const NetworkException('offline'));
      await bloc.stream.firstWhere((state) => state is ReportError);
      bloc.add(const ReportSubmitted(tReport));
      await bloc.stream.firstWhere((state) => state is ReportSuccess);
      expect(calls, 2);
      await bloc.close();
    },
  );

  group('ReportState equality', () {
    test('ReportInitial instances are equal', () {
      expect(ReportInitial(), equals(ReportInitial()));
    });

    test('ReportSubmitting instances are equal', () {
      expect(ReportSubmitting(), equals(ReportSubmitting()));
    });

    test('ReportSuccess instances are equal', () {
      expect(ReportSuccess(), equals(ReportSuccess()));
    });

    test('ReportError instances with same message are equal', () {
      expect(ReportError('msg'), equals(ReportError('msg')));
    });
  });

  group('ReportEvent equality', () {
    test('ReportSubmitted with same report are equal', () {
      expect(ReportSubmitted(tReport), equals(ReportSubmitted(tReport)));
    });
  });
}
