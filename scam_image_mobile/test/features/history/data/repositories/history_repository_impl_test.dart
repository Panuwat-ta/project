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
}
