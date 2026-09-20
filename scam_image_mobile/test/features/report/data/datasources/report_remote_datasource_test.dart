import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/network/api_endpoints.dart';
import 'package:scam_image_mobile/features/report/data/datasources/report_remote_datasource.dart';
import 'package:scam_image_mobile/features/report/data/models/scam_report_model.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ReportRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = ReportRemoteDataSourceImpl(dio: dio);
  });

  test('submitReport posts canonical snake_case body', () async {
    when(
      () => dio.post<void>(ApiEndpoints.reports, data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response<void>(
        statusCode: 201,
        requestOptions: RequestOptions(path: ApiEndpoints.reports),
      ),
    );
    const report = ScamReportModel(
      scanId: '00000000-0000-0000-0000-000000000001',
      category: 'fake_slip',
      description: 'รายละเอียดมากกว่าสิบตัวอักษร',
      platform: 'LINE',
      allowResearchUse: true,
    );

    await dataSource.submitReport(report);

    final body =
        verify(
              () => dio.post<void>(
                ApiEndpoints.reports,
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(body['scan_id'], report.scanId);
    expect(body['category'], 'fake_slip');
    expect(body['allow_research_use'], isTrue);
  });

  test('getCategories extracts Thai labels from backend envelope', () async {
    when(() => dio.get<dynamic>(ApiEndpoints.reportCategories)).thenAnswer(
      (_) async => Response<dynamic>(
        data: {
          'categories': [
            {
              'key': 'fake_slip',
              'label_th': 'สลิปปลอม',
              'label_en': 'Fake Slip',
            },
            {'key': 'other', 'label_th': 'อื่น ๆ', 'label_en': 'Other'},
          ],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiEndpoints.reportCategories),
      ),
    );

    expect(await dataSource.getCategories(), ['สลิปปลอม', 'อื่น ๆ']);
  });

  test(
    'getCategories accepts direct list and safely handles unknown body',
    () async {
      when(() => dio.get<dynamic>(ApiEndpoints.reportCategories)).thenAnswer(
        (_) async => Response<dynamic>(
          data: ['A', 'B'],
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiEndpoints.reportCategories),
        ),
      );
      expect(await dataSource.getCategories(), ['A', 'B']);

      when(() => dio.get<dynamic>(ApiEndpoints.reportCategories)).thenAnswer(
        (_) async => Response<dynamic>(
          data: 'invalid',
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiEndpoints.reportCategories),
        ),
      );
      expect(await dataSource.getCategories(), isEmpty);
    },
  );
}
