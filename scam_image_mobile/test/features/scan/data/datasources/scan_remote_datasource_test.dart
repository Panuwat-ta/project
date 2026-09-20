import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/core/network/api_endpoints.dart';
import 'package:scam_image_mobile/features/scan/data/datasources/scan_remote_datasource.dart';

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
      consentForResearch: true,
      clientRequestId: 'request-1',
      scanName: 'sample',
    );

    expect(id, 'scan-123');
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
      () => dataSource.submitScan(
        filePath: image.path,
        consentForResearch: false,
        clientRequestId: 'request-2',
      ),
      throwsA(isA<ServerException>()),
    );
  });
}
