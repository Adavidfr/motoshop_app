// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/providers/theme_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(
    const ProviderScope(
      child: MotoshopApp(),
    ),
  );
}

class MotoshopApp extends ConsumerWidget {
  const MotoshopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final isDark = ref.watch(themeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.dark : AppTheme.light,
      routerConfig: router,
    );
  }
}
