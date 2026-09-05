import 'package:dio/dio.dart';

import '../network/dio_client.dart';
import '../storage/secure_storage.dart';
import '../storage/database_helper.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

// ── Scan ──────────────────────────────────────────────────────────────────────
import '../../features/scan/data/datasources/scan_remote_datasource.dart';
import '../../features/scan/data/repositories/scan_repository_impl.dart';
import '../../features/scan/domain/repositories/scan_repository.dart';

// ── Result ────────────────────────────────────────────────────────────────────
import '../../features/result/data/datasources/result_local_datasource.dart';
import '../../features/result/data/datasources/result_remote_datasource.dart';
import '../../features/result/data/repositories/result_repository_impl.dart';
import '../../features/result/domain/repositories/result_repository.dart';


// ── History ───────────────────────────────────────────────────────────────────
// ── History ───────────────────────────────────────────────────────────────────
import '../../features/history/data/datasources/history_remote_datasource.dart';
import '../../features/history/data/datasources/history_local_datasource.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';

// ── Report ────────────────────────────────────────────────────────────────────
import '../../features/report/data/datasources/report_remote_datasource.dart';
import '../../features/report/data/repositories/report_repository_impl.dart';
import '../../features/report/domain/repositories/report_repository.dart';

// ── Settings ──────────────────────────────────────────────────────────────────
import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple service locator that wires all real dependencies together.
///
/// Call [ServiceLocator.init] before [runApp] in `main.dart`.
/// Access the wired repositories via the static fields and pass them to
/// BLoC/Cubit constructors in [MultiBlocProvider] in `main.dart`.
class ServiceLocator {
  ServiceLocator._();

  // ── Infrastructure ──────────────────────────────────────────────────────────
  static late SecureStorage secureStorage;
  static late Dio dio;

  // ── Repositories ────────────────────────────────────────────────────────────
  static late AuthRepository authRepository;
  static late ScanRepository scanRepository;
  static late ResultRepository resultRepository;
  static late HistoryRepository historyRepository;
  static late ReportRepository reportRepository;
  static late SettingsRepository settingsRepository;

  /// Initialises all dependencies in dependency order.
  static Future<void> init() async {
    // ── Storage ──────────────────────────────────────────────────────────────
    secureStorage = SecureStorage();

    // ── Network ──────────────────────────────────────────────────────────────
    final apiBaseUrl = dotenv.env['API_BASE_URL'];
    if (apiBaseUrl == null || apiBaseUrl.trim().isEmpty) {
      throw StateError('API_BASE_URL is required and must be configured in .env');
    }
    dio = DioClient.createDio(
      secureStorage: secureStorage,
      baseUrl: apiBaseUrl.trim(),
    );

    // ── Auth ──────────────────────────────────────────────────────────────────
    final authRemote = AuthRemoteDataSourceImpl(dio: dio);
    final authLocal = AuthLocalDataSource(secureStorage: secureStorage);
    authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemote,
      localDataSource: authLocal,
    );

    // ── Scan ──────────────────────────────────────────────────────────────────
    final scanRemote = ScanRemoteDataSourceImpl(dio: dio);
    scanRepository = ScanRepositoryImpl(remoteDataSource: scanRemote);

    // ── Result ────────────────────────────────────────────────────────────────
    final resultRemote = ResultRemoteDataSourceImpl(dio: dio);
    final resultLocal = ResultLocalDataSourceImpl(databaseHelper: DatabaseHelper.instance);
    resultRepository = ResultRepositoryImpl(remoteDataSource: resultRemote, localDataSource: resultLocal);

    // ── History ───────────────────────────────────────────────────────────────
    final historyRemote = HistoryRemoteDataSourceImpl(dio: dio);
    final historyLocal = HistoryLocalDataSourceImpl(databaseHelper: DatabaseHelper.instance);
    historyRepository = HistoryRepositoryImpl(
      remoteDataSource: historyRemote,
      localDataSource: historyLocal,
    );

    // ── Report ────────────────────────────────────────────────────────────────
    final reportRemote = ReportRemoteDataSourceImpl(dio: dio);
    reportRepository = ReportRepositoryImpl(remoteDataSource: reportRemote);

    // ── Settings ──────────────────────────────────────────────────────────────
    final settingsLocal = SettingsLocalDataSourceImpl(secureStorage: secureStorage);
    final settingsRemote = SettingsRemoteDataSourceImpl(dio: dio);
    settingsRepository = SettingsRepositoryImpl(
      remoteDataSource: settingsRemote,
      localDataSource: settingsLocal,
    );
  }
}
