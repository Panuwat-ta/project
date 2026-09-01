import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:scam_image_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Test', () {
    testWidgets('Full authentication and navigation flow', (tester) async {
      // 0. Clear secure storage so we always start at onboarding
      const storage = FlutterSecureStorage();
      await storage.deleteAll();

      // 1. Start the app
      app.main();
      
      // Wait for the app to settle (animations, network calls to load initial state)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1.5 Handle Onboarding
      final getStartedBtn = find.text('เริ่มใช้งาน');
      if (getStartedBtn.evaluate().isNotEmpty) {
        // Need to check the two consent checkboxes
        final checkboxes = find.byType(CheckboxListTile);
        expect(checkboxes, findsNWidgets(2));
        
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();
        await tester.tap(checkboxes.last);
        await tester.pumpAndSettle();
        
        await tester.tap(getStartedBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 2. Login Flow
      // Find the email field (the first TextFormField)
      final emailField = find.byType(TextFormField).first;
      expect(emailField, findsOneWidget);
      await tester.enterText(emailField, 'test@example.com');
      
      // Find the password field (the last TextFormField)
      final passwordField = find.byType(TextFormField).last;
      expect(passwordField, findsOneWidget);
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Find and tap the Login button
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsOneWidget);
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      
      // Wait for navigation and animations to complete without settling since there is a repeating pulse animation
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));

      // 3. Navigation Flow (Home -> History -> Settings)
      // Verify we are on the Home screen (should have an Upload icon/button)
      expect(find.byIcon(Icons.upload_outlined), findsWidgets);

      // Tap on History tab in BottomNavigationBar
      final historyTab = find.byIcon(Icons.history_outlined);
      if (historyTab.evaluate().isNotEmpty) {
        await tester.tap(historyTab.first);
        await tester.pump(const Duration(seconds: 1));
        // Verify History screen title (usually has a search icon)
        expect(find.byIcon(Icons.search_outlined), findsWidgets);
      }

      // Tap on Settings tab in BottomNavigationBar
      final settingsTab = find.byIcon(Icons.settings_outlined);
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab.first);
        await tester.pump(const Duration(seconds: 1));
        // Verify Settings screen elements (e.g. Theme setting)
        expect(find.byIcon(Icons.palette_outlined), findsWidgets);
      }

      // 4. Logout Flow
      // Scroll down to find the Logout button and tap it
      final logoutButton = find.byIcon(Icons.logout_outlined);
      if (logoutButton.evaluate().isNotEmpty) {
        // Ensure it's visible by scrolling
        await tester.ensureVisible(logoutButton.first);
        await tester.tap(logoutButton.first);
        await tester.pump(const Duration(seconds: 1));
        
        // Confirm logout if there's a dialog
        final confirmButton = find.text('ออกจากระบบ');
        if (confirmButton.evaluate().isNotEmpty) {
          await tester.tap(confirmButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Verify we are back to the Login screen (Email field should be visible again)
        expect(find.byType(TextFormField).first, findsOneWidget);
      }
    });
  });
}
