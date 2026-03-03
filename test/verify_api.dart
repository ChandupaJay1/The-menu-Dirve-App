// ignore_for_file: avoid_print
import 'dart:io';
import 'package:http/http.dart' as http;

// IMPORTANT: Match this with your baseUrl in lib/services/api_service.dart
const String baseUrl = 'http://127.0.0.1:8000/api';

void main() async {
  print('--- API Connectivity Verification ---');
  print('Target URL: $baseUrl');
  print('Checking connection...');

  try {
    // We'll try to hit a public endpoint or just the base path
    // Since we don't have a simple health check, we'll try 'register' with a GET
    // (which should return 405 if reachable) or just check the host.
    final uri = Uri.parse(baseUrl.replaceAll('/api', ''));

    final startTime = DateTime.now();
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    final duration = DateTime.now().difference(startTime);

    print('✅ Success!');
    print('Status Code: ${response.statusCode}');
    print('Response Time: ${duration.inMilliseconds}ms');
    print('\nYour backend is REACHABLE from this machine.');

    if (baseUrl.contains('192.168')) {
      print(
          'Note: Since you are using a local IP, ensure your phone is on the SAME Wi-Fi.');
    } else if (baseUrl.contains('10.0.2.2')) {
      print('Note: 10.0.2.2 only works for Android Emulators.');
    }
  } on SocketException catch (e) {
    print('❌ Connection Failed!');
    print('Error: ${e.message}');
    print('\nPossible reasons:');
    print('1. The backend server is not running.');
    print('2. The IP address in api_service.dart is incorrect.');
    print('3. Firewall is blocking the port (8000).');
    print('4. You are not on the same network (if using physical device).');
    exit(1);
  } catch (e) {
    print('❌ An unexpected error occurred: $e');
    exit(1);
  }
}
