import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProxyHelper {
  static const String proxyIp = '192.168.100.11';
  static const String proxyPort = '8083';

  /// Initializes the global proxy settings.
  /// This should be called before any network requests are made.
  static void initialize() {
    if (kDebugMode) {
      print('DEBUG: Initializing Proxy at $proxyIp:$proxyPort');
      HttpOverrides.global = _MyHttpOverrides();
    }
  }

  /// A simple test function to verify proxy connectivity.
  /// Look for this request in Burp Suite.
  static Future<void> testProxy() async {
    if (!kDebugMode) return;

    print('DEBUG: Testing Proxy connectivity...');
    try {
      final response = await http.get(Uri.parse('https://jsonip.com/'));
      print('DEBUG: Proxy Test Success! IP: ${response.body}');
    } catch (e) {
      print('DEBUG: Proxy Test Failed: $e');
      print('TIP: Ensure Burp Suite is running on $proxyIp:$proxyPort and "Support invisible proxying" is enabled if needed.');
    }
  }
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) {
        return 'PROXY ${ProxyHelper.proxyIp}:${ProxyHelper.proxyPort};';
      }
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
