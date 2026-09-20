import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/features/result/data/datasources/result_local_datasource.dart';
import 'package:scam_image_mobile/features/result/data/datasources/result_remote_datasource.dart';
import 'package:scam_image_mobile/features/result/data/repositories/result_repository_impl.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

class MockResultRemote extends Mock implements ResultRemoteDataSource {}
class MockResultLocal extends Mock implements ResultLocalDataSource {}
class MockAnalysisResult extends Mock implements AnalysisResult {}

void main() {
  test('network failure falls back to cached result', () async {
    final remote = MockResultRemote();
    final local = MockResultLocal();
    final cached = MockAnalysisResult();
    final repository = ResultRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
    when(() => remote.getAnalysisResult('scan-1'))
        .thenThrow(const NetworkException('offline'));
    when(() => local.getResult('scan-1')).thenAnswer((_) async => cached);

    final result = await repository.getAnalysisResult('scan-1');

    expect(identical(result, cached), true);
  });

  test('server 404 is authoritative and does not return stale cache', () async {
    final remote = MockResultRemote();
    final local = MockResultLocal();
    final repository = ResultRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
    when(() => remote.getAnalysisResult('missing'))
        .thenThrow(const ServerException('Not found', statusCode: 404));

    expect(
      () => repository.getAnalysisResult('missing'),
      throwsA(isA<ServerException>()),
    );
    verifyNever(() => local.getResult(any()));
  });
}
