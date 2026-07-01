import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// ── BLoC / Cubit imports ──────────────────────────────────────────────────────
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/splash_cubit.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/report/presentation/bloc/report_bloc.dart';
import 'features/result/presentation/bloc/result_bloc.dart';
import 'features/scan/presentation/bloc/scan_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.init();
  runApp(const ScamGuardApp());
}

class ScamGuardApp extends StatelessWidget {
  const ScamGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth
        BlocProvider<SplashCubit>(
          create: (_) => SplashCubit(ServiceLocator.authRepository),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(ServiceLocator.authRepository),
        ),

        // Scan (used by AnalysisLoadingScreen)
        BlocProvider<ScanBloc>(
          create: (_) => ScanBloc(repository: ServiceLocator.scanRepository),
        ),

        // Result
        BlocProvider<ResultBloc>(
          create: (_) =>
              ResultBloc(repository: ServiceLocator.resultRepository),
        ),

        // History
        BlocProvider<HistoryBloc>(
          create: (_) =>
              HistoryBloc(repository: ServiceLocator.historyRepository),
        ),

        // Report
        BlocProvider<ReportBloc>(
          create: (_) =>
              ReportBloc(repository: ServiceLocator.reportRepository),
        ),

        // Settings
        BlocProvider<SettingsCubit>(
          create: (_) =>
              SettingsCubit(repository: ServiceLocator.settingsRepository),
        ),

        // Notifications (no external repository — loads mock/push data)
        BlocProvider<NotificationsCubit>(
          create: (_) => NotificationsCubit()..loadNotifications(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'ScamGuard',
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
