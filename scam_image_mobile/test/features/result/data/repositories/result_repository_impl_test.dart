import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/features/result/data/datasources/result_local_datasource.dart';
import 'package:scam_image_mobile/features/result/data/datasources/result_remote_datasource.dart';
import 'package:scam_image_mobile/features/result/data/models/analysis_result_model.dart';
import 'package:scam_image_mobile/features/result/data/repositories/result_repository_impl.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

class MockResultRemote extends Mock implements ResultRemoteDataSource {}

class MockResultLocal extends Mock implements ResultLocalDataSource {}

class MockAnalysisResult extends Mock implements AnalysisResult {}

AnalysisResultModel freshResult() => AnalysisResultModel(
  scanId: 'scan-1',
  taskId: 'scan-1',
  status: 'completed',
  riskScore: 20,
  riskLevel: RiskLevel.low,
  summary: 'ok',
  createdAt: DateTime.utc(2026, 9, 20),
  factors: const [],
);

void main() {
  test('network failure falls back to cached result', () async {
    final remote = MockResultRemote();
    final local = MockResultLocal();
    final cached = MockAnalysisResult();
    final repository = ResultRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
    when(
      () => remote.getAnalysisResult('scan-1'),
    ).thenThrow(const NetworkException('offline'));
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
    when(
      () => remote.getAnalysisResult('missing'),
    ).thenThrow(const ServerException('Not found', statusCode: 404));

    expect(
      () => repository.getAnalysisResult('missing'),
      throwsA(isA<ServerException>()),
    );
    verifyNever(() => local.getResult(any()));
  });

  test(
    'remote success is returned and cached when local datasource exists',
    () async {
      final remote = MockResultRemote();
      final local = MockResultLocal();
      final fresh = freshResult();
      final repository = ResultRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );
      when(
        () => remote.getAnalysisResult('scan-1'),
      ).thenAnswer((_) async => fresh);
      when(() => local.cacheResult(fresh)).thenAnswer((_) async {});

      final result = await repository.getAnalysisResult('scan-1');

      expect(identical(result, fresh), isTrue);
      verify(() => local.cacheResult(fresh)).called(1);
    },
  );

  test('cache write failure never hides a successful remote result', () async {
    final remote = MockResultRemote();
    final local = MockResultLocal();
    final fresh = freshResult();
    final repository = ResultRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
    when(
      () => remote.getAnalysisResult('scan-1'),
    ).thenAnswer((_) async => fresh);
    when(() => local.cacheResult(fresh)).thenThrow(StateError('disk full'));

    final result = await repository.getAnalysisResult('scan-1');

    expect(identical(result, fresh), isTrue);
  });

  test('remote success works when no local datasource is configured', () async {
    final remote = MockResultRemote();
    final fresh = freshResult();
    final repository = ResultRepositoryImpl(remoteDataSource: remote);
    when(
      () => remote.getAnalysisResult('scan-1'),
    ).thenAnswer((_) async => fresh);

    final result = await repository.getAnalysisResult('scan-1');

    expect(identical(result, fresh), isTrue);
  });

  test('network failure rethrows when cache has no matching result', () async {
    final remote = MockResultRemote();
    final local = MockResultLocal();
    final repository = ResultRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
    when(
      () => remote.getAnalysisResult('scan-1'),
    ).thenThrow(const NetworkException('offline'));
    when(() => local.getResult('scan-1')).thenAnswer((_) async => null);

    await expectLater(
      repository.getAnalysisResult('scan-1'),
      throwsA(isA<NetworkException>()),
    );
  });

  test(
    'network failure rethrows when no local datasource is configured',
    () async {
      final remote = MockResultRemote();
      final repository = ResultRepositoryImpl(remoteDataSource: remote);
      when(
        () => remote.getAnalysisResult('scan-1'),
      ).thenThrow(const NetworkException('offline'));

      await expectLater(
        repository.getAnalysisResult('scan-1'),
        throwsA(isA<NetworkException>()),
      );
    },
  );
}
