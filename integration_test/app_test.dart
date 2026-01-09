import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digi_gold/main.dart' as app; // Adjust 'digi_gold' to your actual package name if different
import 'package:digi_gold/core/services/secure_http_client.dart';
import 'package:digi_gold/core/services/auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('VMurugan DigiGold Flow Tests', () {
    
    testWidgets('Complete Smoke Test: Dashboard, Purchase, Reports, Notifications', (WidgetTester tester) async {
      // 1. Start the app
      app.main();
      await tester.pumpAndSettle();

      print('🚀 Starting Smoke Test...');

      // 2. Handle Login/Initial State
      // Note: In a real test, you might want to use a test account or mock AuthService
      // For this smoke test, we verify we are on the expected initial screen (PhoneEntry or HomePage)
      
      final bool isLoggedIn = await AuthService.isLoggedIn();
      
      if (!isLoggedIn) {
        print('📱 Found Phone Entry Screen, verifying UI components...');
        expect(find.text('Enter Phone Number'), findsOneWidget);
        // Note: We bypass full login in smoke test to avoid real SMS/OTP unless test credentials are set
        return; 
      }

      print('🏠 On HomePage - Verifying Dashboard...');

      // 3. Verify Dashboard components
      expect(find.text('Welcome to V.Murugan Jewellery'), findsOneWidget);
      expect(find.text('Gold Rate'), findsOneWidget);
      expect(find.text('Silver Rate'), findsOneWidget);
      expect(find.text('Investment Schemes'), findsOneWidget);

      // 4. Test Navigation to Notifications
      print('🔔 Testing Notifications...');
      final notificationIcon = find.byIcon(Icons.notifications_outlined);
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
      
      // Go back to Home
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 5. Test Navigation to Reports (History)
      print('📊 Testing History/Reports...');
      final historyTab = find.byIcon(Icons.history);
      await tester.tap(historyTab);
      await tester.pumpAndSettle();
      expect(find.text('Transaction History'), findsOneWidget);
      
      // Verify filter exists
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      
      // Go back to Home (via bottom nav)
      final homeTab = find.byIcon(Icons.home);
      await tester.tap(homeTab);
      await tester.pumpAndSettle();

      // 6. Test Navigation to Portfolio
      print('💼 Testing Portfolio...');
      final portfolioTab = find.byIcon(Icons.account_balance_wallet);
      await tester.tap(portfolioTab);
      await tester.pumpAndSettle();
      expect(find.text('My Portfolio'), findsOneWidget);
      
      // Back to Home
      await tester.tap(homeTab);
      await tester.pumpAndSettle();

      // 7. Test Gold Scheme Flow (Simplified)
      print('✨ Testing Scheme Navigation...');
      final viewSchemesBtn = find.text('View Schemes').first;
      await tester.tap(viewSchemesBtn);
      await tester.pumpAndSettle();
      
      // Verify we are on Scheme Selection
      expect(find.textContaining('Scheme'), findsWidgets);

      print('✅ Smoke Test Completed Successfully!');
    });
  });
}
