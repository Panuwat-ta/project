import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/core/network/api_endpoints.dart';
import 'package:scam_image_mobile/features/result/data/datasources/result_remote_datasource.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

class MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> response(Map<String, dynamic>? data) => Response(
  data: data,
  statusCode: 200,
  requestOptions: RequestOptions(path: '/scan/id'),
);

void main() {
  late MockDio dio;
  late ResultRemoteDataSourceImpl dataSource;

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=http://localhost:8000/api/v1',
    );
  });

  setUp(() {
    dio = MockDio();
    dataSource = ResultRemoteDataSourceImpl(dio: dio);
  });

  test('getAnalysisResult parses canonical scan response', () async {
    when(
      () => dio.get<Map<String, dynamic>>(ApiEndpoints.scanResult('scan-1')),
    ).thenAnswer(
      (_) async => response({
        'id': 'scan-1',
        'status': 'completed',
        'total_risk_score': 80,
        'risk_grade': 'high',
        'text_score': 20,
        'visual_score': 80,
        'source_score': 10,
        'ai_gen_probability': 0.7,
        'created_at': '2026-09-20T00:00:00Z',
      }),
    );

    final result = await dataSource.getAnalysisResult('scan-1');

    expect(result.taskId, 'scan-1');
    expect(result.riskScore, 80);
    expect(result.riskLevel, RiskLevel.high);
    expect(result.factors, hasLength(3));
  });

  test('getAnalysisResult rejects empty successful response', () async {
    when(
      () => dio.get<Map<String, dynamic>>(ApiEndpoints.scanResult('scan-1')),
    ).thenAnswer((_) async => response(null));

    expect(
      dataSource.getAnalysisResult('scan-1'),
      throwsA(isA<ServerException>()),
    );
  });

  test('getAnalysisResult maps Dio 404 to typed server exception', () async {
    when(
      () => dio.get<Map<String, dynamic>>(ApiEndpoints.scanResult('missing')),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/scan/missing'),
        response: Response(
          requestOptions: RequestOptions(path: '/scan/missing'),
          statusCode: 404,
          data: {'detail': 'Scan not found'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      dataSource.getAnalysisResult('missing'),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });
}
