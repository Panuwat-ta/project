import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/features/report/data/datasources/report_remote_datasource.dart';
import 'package:scam_image_mobile/features/report/data/models/scam_report_model.dart';
import 'package:scam_image_mobile/features/report/data/repositories/report_repository_impl.dart';
import 'package:scam_image_mobile/features/report/domain/entities/scam_report.dart';

class MockReportRemote extends Mock implements ReportRemoteDataSource {}
class FakeReportModel extends Fake implements ScamReportModel {}

void main() {
  setUpAll(() => registerFallbackValue(FakeReportModel()));

  test('submitReport rejects missing scan id before network call', () async {
    final remote = MockReportRemote();
    final repository = ReportRepositoryImpl(remoteDataSource: remote);
    const report = ScamReport(
      category: 'fake_slip',
      description: 'รายละเอียดที่ยาวเพียงพอ',
    );

    expect(
      () => repository.submitReport(report),
      throwsA(isA<ValidationException>()),
    );
    verifyNever(() => remote.submitReport(any()));
  });

  test('submitReport forwards valid report with scan id', () async {
    final remote = MockReportRemote();
    final repository = ReportRepositoryImpl(remoteDataSource: remote);
    when(() => remote.submitReport(any())).thenAnswer((_) async {});
    const report = ScamReport(
      scanId: 'scan-1',
      category: 'fake_slip',
      description: 'รายละเอียดที่ยาวเพียงพอ',
    );

    await repository.submitReport(report);

    verify(() => remote.submitReport(any())).called(1);
  });
}
