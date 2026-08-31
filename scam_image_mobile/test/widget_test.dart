// Basic smoke test — verifies the ScamGuardApp widget tree can be built and
// that the router renders the initial splash route without errors.

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scam_image_mobile/main.dart';
import 'package:scam_image_mobile/core/di/injection_container.dart';
import 'package:scam_image_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:scam_image_mobile/features/scan/domain/repositories/scan_repository.dart';
import 'package:scam_image_mobile/features/result/domain/repositories/result_repository.dart';
import 'package:scam_image_mobile/features/history/domain/repositories/history_repository.dart';
import 'package:scam_image_mobile/features/report/domain/repositories/report_repository.dart';
import 'package:scam_image_mobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:scam_image_mobile/features/settings/domain/entities/consent_setting.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockScanRepository extends Mock implements ScanRepository {}
class MockResultRepository extends Mock implements ResultRepository {}
class MockHistoryRepository extends Mock implements HistoryRepository {}
class MockReportRepository extends Mock implements ReportRepository {}
class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  testWidgets('App smoke test — renders without error',
      (WidgetTester tester) async {
    ServiceLocator.authRepository = MockAuthRepository();
    ServiceLocator.scanRepository = MockScanRepository();
    ServiceLocator.resultRepository = MockResultRepository();
    ServiceLocator.historyRepository = MockHistoryRepository();
    ServiceLocator.reportRepository = MockReportRepository();
    
    final settingsRepo = MockSettingsRepository();
    when(() => settingsRepo.getLanguage()).thenAnswer((_) async => 'th');
    when(() => settingsRepo.getThemeMode()).thenAnswer((_) async => ThemeMode.system);
    when(() => settingsRepo.getConsents()).thenAnswer((_) async => const ConsentSetting(processingConsent: true, researchConsent: true));
    ServiceLocator.settingsRepository = settingsRepo;

    await tester.pumpWidget(const ScamGuardApp());
    // The router shows the splash screen with the title on startup.
    expect(find.text('Scam Image Detection'), findsOneWidget);
    // Advance time by 3 seconds to clear SplashCubit's Future.delayed
    await tester.pump(const Duration(seconds: 3));
  });
}
