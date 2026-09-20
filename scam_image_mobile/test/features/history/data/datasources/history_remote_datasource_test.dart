import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/network/api_endpoints.dart';
import 'package:scam_image_mobile/features/history/data/datasources/history_remote_datasource.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late HistoryRemoteDataSourceImpl dataSource;

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=http://localhost:8000/api/v1',
    );
  });

  setUp(() {
    dio = MockDio();
    dataSource = HistoryRemoteDataSourceImpl(dio: dio);
  });

  test(
    'getScanHistory parses backend items envelope and sends pagination/search',
    () async {
      when(
        () => dio.get<dynamic>(
          ApiEndpoints.history,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: {
            'items': [
              {
                'scan_id': 'scan-1',
                'risk_score': 70,
                'risk_level': 'high',
                'status': 'completed',
                'created_at': '2026-09-20T00:00:00Z',
                'title': 'Example',
              },
            ],
            'total': 1,
            'page': 2,
            'limit': 100,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiEndpoints.history),
        ),
      );

      final items = await dataSource.getScanHistory(
        page: 2,
        limit: 100,
        keyword: 'needle',
      );

      expect(items, hasLength(1));
      expect(items.single.scanId, 'scan-1');
      expect(items.single.riskLevel, RiskLevel.high);
      final captured =
          verify(
                () => dio.get<dynamic>(
                  ApiEndpoints.history,
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['page'], 2);
      expect(captured['limit'], 100);
      expect(captured['keyword'], 'needle');
    },
  );

  test(
    'getScanHistory also accepts direct array and unexpected body becomes empty',
    () async {
      when(
        () => dio.get<dynamic>(
          ApiEndpoints.history,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: <dynamic>[],
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiEndpoints.history),
        ),
      );
      expect(await dataSource.getScanHistory(), isEmpty);

      when(
        () => dio.get<dynamic>(
          ApiEndpoints.history,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: 'invalid',
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiEndpoints.history),
        ),
      );
      expect(await dataSource.getScanHistory(), isEmpty);
    },
  );

  test('delete and clear use canonical history endpoints', () async {
    when(() => dio.delete<void>(ApiEndpoints.historyById('scan-1'))).thenAnswer(
      (_) async => Response<void>(
        statusCode: 200,
        requestOptions: RequestOptions(
          path: ApiEndpoints.historyById('scan-1'),
        ),
      ),
    );
    when(() => dio.delete<void>(ApiEndpoints.history)).thenAnswer(
      (_) async => Response<void>(
        statusCode: 204,
        requestOptions: RequestOptions(path: ApiEndpoints.history),
      ),
    );

    await dataSource.deleteScanHistoryItem('scan-1');
    await dataSource.clearAllHistory();

    verify(
      () => dio.delete<void>(ApiEndpoints.historyById('scan-1')),
    ).called(1);
    verify(() => dio.delete<void>(ApiEndpoints.history)).called(1);
  });
}
