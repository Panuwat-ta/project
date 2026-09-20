import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:scam_image_mobile/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:scam_image_mobile/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:scam_image_mobile/features/settings/domain/entities/consent_setting.dart';

class MockSettingsLocal extends Mock implements SettingsLocalDataSource {}
class MockSettingsRemote extends Mock implements SettingsRemoteDataSource {}

void main() {
  late MockSettingsLocal local;
  late MockSettingsRemote remote;
  late SettingsRepositoryImpl repository;

  setUp(() {
    local = MockSettingsLocal();
    remote = MockSettingsRemote();
    repository = SettingsRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
    );
  });

  test('updateConsents is local-only while backend consent route is absent', () async {
    const consent = ConsentSetting(
      processingConsent: true,
      historyConsent: true,
      researchConsent: false,
    );
    when(() => local.saveConsents(consent)).thenAnswer((_) async {});

    await repository.updateConsents(consent);

    verify(() => local.saveConsents(consent)).called(1);
    verifyNoMoreInteractions(remote);
  });

  test('exportPrivacyData fails locally instead of issuing known 404 request', () {
    expect(repository.exportPrivacyData, throwsA(isA<UnsupportedError>()));
    verifyNoMoreInteractions(remote);
  });

  test('deleteAccount forwards password to supported backend route', () async {
    when(() => remote.deleteAccount('secret123')).thenAnswer((_) async {});

    await repository.deleteAccount('secret123');

    verify(() => remote.deleteAccount('secret123')).called(1);
  });
}
