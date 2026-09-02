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
        when(() => mockRepo.submitReport(any()))
            .thenAnswer((_) async {});
        return ReportBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ReportSubmitted(tReport)),
      expect: () => const [
        ReportSubmitting(),
        ReportSuccess(),
      ],
      verify: (_) {
        verify(() => mockRepo.submitReport(tReport)).called(1);
      },
    );

    blocTest<ReportBloc, ReportState>(
      'emits [ReportSubmitting, ReportError] with network message on NetworkException',
      build: () {
        when(() => mockRepo.submitReport(any()))
            .thenThrow(const NetworkException('Connection error'));
        return ReportBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ReportSubmitted(tReport)),
      expect: () => [
        const ReportSubmitting(),
        isA<ReportError>().having(
          (s) => s.message,
          'message',
          contains('เชื่อมต่อ'),
        ),
      ],
    );

    blocTest<ReportBloc, ReportState>(
      'emits [ReportSubmitting, ReportError] with session message on AuthException',
      build: () {
        when(() => mockRepo.submitReport(any()))
            .thenThrow(const AuthException('401'));
        return ReportBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ReportSubmitted(tReport)),
      expect: () => [
        const ReportSubmitting(),
        isA<ReportError>().having(
          (s) => s.message,
          'message',
          contains('เซสชัน'),
        ),
      ],
    );

    blocTest<ReportBloc, ReportState>(
      'emits [ReportSubmitting, ReportError] with generic message on unknown error',
      build: () {
        when(() => mockRepo.submitReport(any()))
            .thenThrow(Exception('unexpected'));
        return ReportBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ReportSubmitted(tReport)),
      expect: () => [
        const ReportSubmitting(),
        isA<ReportError>().having(
          (s) => s.message,
          'message',
          contains('ลองใหม่'),
        ),
      ],
    );
  });

  group('ReportState equality', () {
    test('ReportInitial instances are equal', () {
      expect(const ReportInitial(), equals(const ReportInitial()));
    });

    test('ReportSubmitting instances are equal', () {
      expect(const ReportSubmitting(), equals(const ReportSubmitting()));
    });

    test('ReportSuccess instances are equal', () {
      expect(const ReportSuccess(), equals(const ReportSuccess()));
    });

    test('ReportError instances with same message are equal', () {
      expect(const ReportError('msg'), equals(const ReportError('msg')));
    });
  });

  group('ReportEvent equality', () {
    test('ReportSubmitted with same report are equal', () {
      expect(
        const ReportSubmitted(tReport),
        equals(const ReportSubmitted(tReport)),
      );
    });
  });
}
