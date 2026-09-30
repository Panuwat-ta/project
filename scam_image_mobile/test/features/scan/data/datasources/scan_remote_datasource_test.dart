import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/core/network/api_endpoints.dart';
import 'package:scam_image_mobile/features/scan/data/datasources/scan_remote_datasource.dart';
import 'package:scam_image_mobile/features/scan/domain/entities/analysis_task.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ScanRemoteDataSourceImpl dataSource;
  late File image;

  setUp(() async {
    dio = MockDio();
    dataSource = ScanRemoteDataSourceImpl(dio: dio);
    image = File('${Directory.systemTemp.path}/scamguard-scan-test.jpg');
    await image.writeAsBytes([1, 2, 3, 4]);
  });

  tearDown(() async {
    if (await image.exists()) await image.delete();
  });

  test('submitScan returns canonical backend id', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.scans,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {'id': 'scan-123', 'status': 'uploading', 'progress': 0},
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiEndpoints.scans),
      ),
    );

    final id = await dataSource.submitScan(
      filePath: image.path,
      scanName: '  sample  ',
    );

    expect(id, 'scan-123');
    final captured =
        verify(
              () => dio.post<Map<String, dynamic>>(
                ApiEndpoints.scans,
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as FormData;
    expect(Map<String, String>.fromEntries(captured.fields)['title'], 'sample');
  });

  test('submitScan rejects successful response without id', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.scans,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {'status': 'uploading'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiEndpoints.scans),
      ),
    );

    expect(
      () => dataSource.submitScan(filePath: image.path),
      throwsA(isA<ServerException>()),
    );
  });

  test('submitScan omits title when scanName is blank', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.scans,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {'id': 'scan-blank'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiEndpoints.scans),
      ),
    );

    expect(
      await dataSource.submitScan(filePath: image.path, scanName: '   '),
      'scan-blank',
    );
    final captured =
        verify(
              () => dio.post<Map<String, dynamic>>(
                ApiEndpoints.scans,
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as FormData;
    expect(
      Map<String, String>.fromEntries(captured.fields),
      isNot(contains('title')),
    );
  });

  test('submitScan rejects empty or non-string backend id', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.scans,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {'id': '   '},
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiEndpoints.scans),
      ),
    );
    await expectLater(
      dataSource.submitScan(filePath: image.path),
      throwsA(isA<ServerException>()),
    );

    when(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.scans,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {'id': 123},
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiEndpoints.scans),
      ),
    );
    await expectLater(
      dataSource.submitScan(filePath: image.path),
      throwsA(isA<ServerException>()),
    );
  });

  test('submitScan rejects empty response body', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.scans,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: null,
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiEndpoints.scans),
      ),
    );

    await expectLater(
      dataSource.submitScan(filePath: image.path),
      throwsA(isA<ServerException>()),
    );
  });

  test('submitScan maps Dio connectivity errors to NetworkException', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.scans,
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.scans),
        type: DioExceptionType.connectionError,
        message: 'offline',
      ),
    );

    await expectLater(
      dataSource.submitScan(filePath: image.path),
      throwsA(isA<NetworkException>()),
    );
  });

  test('getScanStatus parses canonical backend status', () async {
    final path = ApiEndpoints.scanById('scan-1');
    when(() => dio.get<Map<String, dynamic>>(path)).thenAnswer(
      (_) async => Response(
        data: {'id': 'scan-1', 'status': 'processing_visual', 'progress': 55},
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      ),
    );

    final task = await dataSource.getScanStatus('scan-1');

    expect(task.taskId, 'scan-1');
    expect(task.status, AnalysisTaskStatus.processingVisual);
    expect(task.progress, 55);
  });

  test('getScanStatus rejects null body and maps Dio errors', () async {
    final path = ApiEndpoints.scanById('scan-1');
    when(() => dio.get<Map<String, dynamic>>(path)).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: null,
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      ),
    );
    await expectLater(
      dataSource.getScanStatus('scan-1'),
      throwsA(isA<ServerException>()),
    );

    when(() => dio.get<Map<String, dynamic>>(path)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionTimeout,
        message: 'timeout',
      ),
    );
    await expectLater(
      dataSource.getScanStatus('scan-1'),
      throwsA(isA<NetworkException>()),
    );
  });
}
