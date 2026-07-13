// lib/core/config/app_config.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  static String? resolveImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    String clean = raw.trim();
    final baseDomain = baseUrl.replaceAll('/api', '');
    
    if (clean.contains('localhost') || clean.contains('127.0.0.1') || clean.contains('10.0.2.2')) {
      final mediaIndex = clean.indexOf('/media/');
      if (mediaIndex != -1) {
        clean = clean.substring(mediaIndex);
      }
    }
    
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final path = clean.startsWith('/') ? clean : '/$clean';
    return '$baseDomain$path';
  }

  static const String appName = 'Flutter Shop App';
  static const double taxRate = 0.15; // IVA Ecuador 15 %
}