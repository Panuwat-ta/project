import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
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

  test(
    'getScanHistory sends optional risk/date filters and omits blank keyword',
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
      final from = DateTime.utc(2026, 9, 1);
      final to = DateTime.utc(2026, 9, 20, 23, 59);

      await dataSource.getScanHistory(
        riskLevel: 'high',
        fromDate: from,
        toDate: to,
        keyword: '',
      );

      final captured =
          verify(
                () => dio.get<dynamic>(
                  ApiEndpoints.history,
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['risk_level'], 'high');
      expect(captured['fromDate'], from.toIso8601String());
      expect(captured['toDate'], to.toIso8601String());
      expect(captured, isNot(contains('keyword')));
    },
  );

  test(
    'getScanHistory accepts data envelope, null body, and empty map',
    () async {
      when(
        () => dio.get<dynamic>(
          ApiEndpoints.history,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: {
            'data': [
              {
                'scan_id': 'scan-data',
                'risk_score': 20,
                'risk_level': 'low',
                'status': 'completed',
                'created_at': '2026-09-20T00:00:00Z',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiEndpoints.history),
        ),
      );
      expect((await dataSource.getScanHistory()).single.scanId, 'scan-data');

      when(
        () => dio.get<dynamic>(
          ApiEndpoints.history,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: null,
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
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiEndpoints.history),
        ),
      );
      expect(await dataSource.getScanHistory(), isEmpty);
    },
  );

  test('getScanHistory maps Dio connectivity errors', () async {
    when(
      () => dio.get<dynamic>(
        ApiEndpoints.history,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.history),
        type: DioExceptionType.connectionError,
        message: 'offline',
      ),
    );

    await expectLater(
      dataSource.getScanHistory(),
      throwsA(isA<NetworkException>()),
    );
  });

  test('delete and clear map Dio connectivity errors', () async {
    final itemPath = ApiEndpoints.historyById('scan-1');
    when(() => dio.delete<void>(itemPath)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: itemPath),
        type: DioExceptionType.connectionError,
        message: 'offline',
      ),
    );
    await expectLater(
      dataSource.deleteScanHistoryItem('scan-1'),
      throwsA(isA<NetworkException>()),
    );

    when(() => dio.delete<void>(ApiEndpoints.history)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.history),
        type: DioExceptionType.connectionTimeout,
        message: 'timeout',
      ),
    );
    await expectLater(
      dataSource.clearAllHistory(),
      throwsA(isA<NetworkException>()),
    );
  });
}
