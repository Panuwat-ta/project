import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/splash_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SplashCubit>().checkSession();
    });
  }

  void _handleState(BuildContext context, SplashState state) {
    if (state is SplashAuthenticated) {
      // Push the real user from the restored session into AuthBloc so
      // screens that watch it (settings, profile) show actual data.
      context.read<AuthBloc>().add(AuthSessionRestored(state.user));
      context.go('/main/home');
    } else if (state is SplashUnauthenticated) {
      context.go('/login');
    } else if (state is SplashConsentRequired) {
      context.go('/onboarding');
    } else if (state is SplashFailure) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return BlocListener<SplashCubit, SplashState>(
      listener: _handleState,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.shield_outlined,
                      size: 96,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ScamGuard',
                    style: AppTypography.headlineLgMobile(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'splash_tagline'.tr(context),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyBase(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    liveRegion: true,
                    label: 'splash_loading'.tr(context),
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          if (!MediaQuery.disableAnimationsOf(context))
                            const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'splash_loading'.tr(context),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
