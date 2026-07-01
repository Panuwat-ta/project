// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Placeholder screens — each will be replaced by a real implementation in a
/// later task.  They intentionally contain only the minimum boilerplate needed
/// to compile and render something visible.
/// ---------------------------------------------------------------------------

class SplashPlaceholderScreen extends StatelessWidget {
  const SplashPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Splash Screen')));
}

class OnboardingPlaceholderScreen extends StatelessWidget {
  const OnboardingPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Onboarding Screen')));
}

class LoginPlaceholderScreen extends StatelessWidget {
  const LoginPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Login Screen')));
}

class RegisterPlaceholderScreen extends StatelessWidget {
  const RegisterPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Register Screen')));
}

// ── Main Shell ───────────────────────────────────────────────────────────────

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Home Screen')));
}

class HistoryPlaceholderScreen extends StatelessWidget {
  const HistoryPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('History Screen')));
}

class HistoryDetailPlaceholderScreen extends StatelessWidget {
  const HistoryDetailPlaceholderScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('History Detail Screen — $id')));
}

class ReportPlaceholderScreen extends StatelessWidget {
  const ReportPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Report Screen')));
}

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Settings Screen')));
}

class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Profile Screen')));
}

class PrivacyPlaceholderScreen extends StatelessWidget {
  const PrivacyPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Privacy Screen')));
}

// ── Standalone screens ───────────────────────────────────────────────────────

class CropPlaceholderScreen extends StatelessWidget {
  const CropPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Image Crop Screen')));
}

class LoadingPlaceholderScreen extends StatelessWidget {
  const LoadingPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Loading Screen')));
}

class ResultPlaceholderScreen extends StatelessWidget {
  const ResultPlaceholderScreen({super.key, required this.scanId});
  final String scanId;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Result Screen — $scanId')));
}

class HeatmapPlaceholderScreen extends StatelessWidget {
  const HeatmapPlaceholderScreen({super.key, required this.scanId});
  final String scanId;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Heatmap Screen — $scanId')));
}

class NotificationsPlaceholderScreen extends StatelessWidget {
  const NotificationsPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Notifications Screen')));
}
