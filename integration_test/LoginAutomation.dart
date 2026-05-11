import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:artheca/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Artheca Login Automation Test', () {

    testWidgets('Skenario Login Berhasil (Full Flow)', (tester) async {
      app.main();

      print("INFO: Menunggu Onboarding...");

      // 1. HANDLE ONBOARDING
      final continueButton = find.text('CONTINUE EXPLORING');
      final beginButton = find.text('BEGIN YOUR JOURNEY');

      // Tunggu onboarding muncul
      bool foundOnboarding = false;
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (tester.any(continueButton)) {
          foundOnboarding = true;
          break;
        }
      }

      if (!foundOnboarding) fail("Robot nyerah: Onboarding gak ketemu.");

      // Klik 2 kali Continue, 1 kali Begin
      for (int i = 0; i < 2; i++) {
        await tester.tap(continueButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await tester.tap(beginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 2. PROSES LOGIN
      print("INFO: Mengisi data Login...");
      await tester.enterText(find.byKey(const Key('emailField')), 'faiqbolqiah@gmail.com');
      await tester.enterText(find.byKey(const Key('passwordField')), 'faiqfaiq');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('loginButton')));

      // 3. VERIFIKASI PINDAH KE HOME (SABAR)
      print("INFO: Memverifikasi transisi ke Home...");

      // Kita nunggu sampai tulisan 'THE ARTHECA' (Header Home) muncul
      // Kita kasih waktu 15 detik (cukup buat transisi & Supabase check)
      bool reachedHome = false;
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (tester.any(find.text('THE ARTHECA'))) {
          reachedHome = true;
          break;
        }
      }

      // 4. FINAL CHECK
      if (reachedHome) {
        print("SUCCESS: Robot sudah melihat Header Home!");
        expect(find.text('THE ARTHECA'), findsOneWidget);
      } else {
        // Backup plan: kalau Header gak ketemu, cek apakah Form Login sudah hilang
        print("INFO: Header gak ketemu, cek status Form Login...");
        expect(find.byKey(const Key('emailField')), findsNothing);
      }

      print("INFO: Automation Selesai!");
    });
  });
}