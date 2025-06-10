import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Diperlukan untuk MethodChannel
import 'package:flutter_test/flutter_test.dart';
import 'package:historyquizapp/screens/login_screen.dart';
import 'package:historyquizapp/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Inisialisasi binding diperlukan untuk mocking platform channels
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Siapkan mock untuk SharedPreferences dan Geolocator
  // Ini akan berjalan sebelum tes dieksekusi
  setUp(() {
    // 1. Mock untuk SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // 2. Mock untuk Geolocator Platform Channel
    // Ini akan mencegat panggilan ke plugin geolocator
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      // Jika kode meminta lokasi saat ini, berikan data lokasi palsu
      if (methodCall.method == 'getCurrentPosition') {
        return {
          'latitude': 35.6895, // Lokasi palsu (Tokyo)
          'longitude': 139.6917,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'accuracy': 0.0,
          'altitude': 0.0,
          'altitudeAccuracy': 0.0,
          'heading': 0.0,
          'headingAccuracy': 0.0,
          'speed': 0.0,
          'speedAccuracy': 0.0,
          'isMocked': true,
        };
      }
      // Jika kode memeriksa apakah layanan lokasi aktif, jawab 'ya'
      if (methodCall.method == 'isLocationServiceEnabled') {
        return true;
      }
      // Jika kode memeriksa izin, jawab 'sudah diberikan'
      if (methodCall.method == 'checkPermission') {
        return 'whileInUse'; // Ini merepresentasikan LocationPermission.whileInUse
      }
      return null;
    });
  });
  
  // Bersihkan mock handler setelah tes selesai
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/geolocator'), null);
  });

  testWidgets('Login screen harus menampilkan elemen yang diperlukan setelah inisialisasi', (WidgetTester tester) async {
    // Render LoginScreen di dalam MaterialApp
    await tester.pumpWidget(MaterialApp(
      theme: DynamicAppTheme.lightTheme,
      home: const LoginScreen(),
    ));

    // Tunggu hingga semua frame dan proses asinkron (termasuk yang di-mock) selesai.
    await tester.pumpAndSettle();

    // Verifikasi bahwa UI yang benar sudah muncul
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
  });
}