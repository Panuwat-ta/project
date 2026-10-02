import 'dart:async';
import 'package:scam_image_mobile/core/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/features/history/data/datasources/history_local_datasource.dart';
import 'package:scam_image_mobile/features/history/data/datasources/history_remote_datasource.dart';
import 'package:scam_image_mobile/features/history/data/models/scan_history_item_model.dart';
import 'package:scam_image_mobile/features/history/data/repositories/history_repository_impl.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

class MockHistoryRemote extends Mock implements HistoryRemoteDataSource {}

class MockHistoryLocal extends Mock implements HistoryLocalDataSource {}

ScanHistoryItemModel item(String id) => ScanHistoryItemModel(
  scanId: id,
  riskScore: 10,
  riskLevel: RiskLevel.low,
  status: 'completed',
  createdAt: DateTime(2026, 1, 1),
  title: 'item $id',
);

void stubRemote(
  MockHistoryRemote remote, {
  required Future<List<ScanHistoryItemModel>> Function(Invocation) answer,
}) {
  when(
    () => remote.getScanHistory(
      page: any(named: 'page'),
      limit: any(named: 'limit'),
      riskLevel: any(named: 'riskLevel'),
      fromDate: any(named: 'fromDate'),
      toDate: any(named: 'toDate'),
      keyword: any(named: 'keyword'),
    ),
  ).thenAnswer(answer);
}

void main() {
  late MockHistoryRemote remote;
  late MockHistoryLocal local;
  late HistoryRepositoryImpl repository;

  setUp(() {
    remote = MockHistoryRemote();
    local = MockHistoryLocal();
    repository = HistoryRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
  });

  test('unfiltered load prefers fresh remote data and caches it', () async {
    final fresh = [item('remote')];
    stubRemote(remote, answer: (_) async => fresh);
    when(() => local.cacheHistory(fresh)).thenAnswer((_) async {});

    final result = await repository.getScanHistory(limit: 100);

    expect(result.single.scanId, 'remote');
    verify(() => local.cacheHistory(fresh)).called(1);
    verifyNever(() => local.getHistory());
  });

  test('unfiltered network failure falls back to local cache', () async {
    final cached = [item('cached')];
    stubRemote(
      remote,
      answer: (_) => Future.error(const NetworkException('offline')),
    );
    when(() => local.getHistory()).thenAnswer((_) async => cached);

    final result = await repository.getScanHistory();

    expect(result.single.scanId, 'cached');
  });

  test('network failure with empty cache keeps original failure', () async {
    stubRemote(
      remote,
      answer: (_) => Future.error(const NetworkException('offline')),
    );
    when(() => local.getHistory()).thenAnswer((_) async => []);

    expect(repository.getScanHistory(), throwsA(isA<NetworkException>()));
  });

  test('filtered request never substitutes unrelated local cache', () async {
    stubRemote(
      remote,
      answer: (_) => Future.error(const NetworkException('offline')),
    );

    expect(
      repository.getScanHistory(keyword: 'needle'),
      throwsA(isA<NetworkException>()),
    );
    verifyNever(() => local.getHistory());
  });
  for (final error in [
    const AuthException('expired'),
    const ServerException('not found', statusCode: 404),
    const ServerException('unavailable', statusCode: 503),
    const ValidationException('malformed response'),
  ]) {
    test('authoritative $error is not replaced with cached history', () async {
      stubRemote(remote, answer: (_) => Future.error(error));
      await expectLater(repository.getScanHistory(), throwsA(same(error)));
      verifyNever(() => local.getHistory());
    });
  }

  test('cache write failure preserves successful fresh history', () async {
    final fresh = [item('fresh')];
    stubRemote(remote, answer: (_) async => fresh);
    when(
      () => local.cacheHistory(fresh),
    ).thenThrow(const CacheException('disk full'));
    expect((await repository.getScanHistory()).single.scanId, 'fresh');
    verifyNever(() => local.getHistory());
  });
  test(
    'response from an invalidated session never reaches history cache',
    () async {
      final storage = SecureStorage();
      final pending = Completer<List<ScanHistoryItemModel>>();
      stubRemote(remote, answer: (_) => pending.future);
      final repository = HistoryRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        sessionStorage: storage,
      );
      final response = repository.getScanHistory();
      final rejected = expectLater(response, throwsA(isA<AuthException>()));
      storage.invalidateAuthSession();
      pending.complete([item('old-user')]);
      await rejected;
      verifyNever(() => local.getHistory());
      storage.dispose();
    },
  );
}
