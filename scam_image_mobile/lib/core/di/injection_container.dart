import 'package:dio/dio.dart';

import '../network/dio_client.dart';
import '../storage/secure_storage.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

// ── Scan ──────────────────────────────────────────────────────────────────────
import '../../features/scan/domain/repositories/scan_repository.dart';
import '../../features/scan/presentation/bloc/scan_bloc.dart';

// ── Result ────────────────────────────────────────────────────────────────────
import '../../features/result/domain/repositories/result_repository.dart';
import '../../features/result/presentation/bloc/result_bloc.dart';


// ── History ───────────────────────────────────────────────────────────────────
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';

// ── Report ────────────────────────────────────────────────────────────────────
import '../../features/report/data/datasources/report_remote_datasource.dart';
import '../../features/report/data/repositories/report_repository_impl.dart';
import '../../features/report/domain/repositories/report_repository.dart';

// ── Settings ──────────────────────────────────────────────────────────────────
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';

/// Simple service locator that wires all real dependencies together.
///
/// Call [ServiceLocator.init] before [runApp] in `main.dart`.
/// Access the wired repositories via the static fields and pass them to
/// BLoC/Cubit constructors in [MultiBlocProvider] in `main.dart`.
class ServiceLocator {
  ServiceLocator._();

  // ── Infrastructure ──────────────────────────────────────────────────────────
  static late final SecureStorage secureStorage;
  static late final Dio dio;

  // ── Repositories ────────────────────────────────────────────────────────────
  static late final AuthRepository authRepository;
  static late final ScanRepository scanRepository;
  static late final ResultRepository resultRepository;
  static late final HistoryRepository historyRepository;
  static late final ReportRepository reportRepository;
  static late final SettingsRepository settingsRepository;

  /// Initialises all dependencies in dependency order.
  static Future<void> init() async {
    // ── Storage ──────────────────────────────────────────────────────────────
    secureStorage = SecureStorage();

    // ── Network ──────────────────────────────────────────────────────────────
    // Base URL is configurable via environment; defaults to localhost for dev.
    dio = DioClient.createDio(
      secureStorage: secureStorage,
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      ),
    );

    // ── Auth ──────────────────────────────────────────────────────────────────
    final authRemote = AuthRemoteDataSourceImpl(dio: dio);
    final authLocal = AuthLocalDataSource(secureStorage: secureStorage);
    authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemote,
      localDataSource: authLocal,
    );

    // ── Scan ──────────────────────────────────────────────────────────────────
    // Using MockScanRepository to prevent connection refused since there is no backend
    scanRepository = MockScanRepository();

    // ── Result ────────────────────────────────────────────────────────────────
    resultRepository = MockResultRepository();

    // ── History ───────────────────────────────────────────────────────────────
    // Using MockHistoryRepository for testing UI flow
    historyRepository = MockHistoryRepository();

    // ── Report ────────────────────────────────────────────────────────────────
    final reportRemote = ReportRemoteDataSourceImpl(dio: dio);
    reportRepository = ReportRepositoryImpl(remoteDataSource: reportRemote);

    // ── Settings ──────────────────────────────────────────────────────────────
    final settingsRemote = SettingsRemoteDataSourceImpl(dio: dio);
    settingsRepository =
        SettingsRepositoryImpl(remoteDataSource: settingsRemote);
  }
}
