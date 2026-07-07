// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(
    const ProviderScope(
      child: MotoshopApp(),
    ),
  );
}

class MotoshopApp extends StatelessWidget {
  const MotoshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const VerificationScreen(),
    );
  }
}

// ── Pantalla de verificación ──────────────────────────────────

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Column(
                  children: [
                    Text(
                      AppConfig.appName,
                      style:
                          tt.displayMedium?.copyWith(color: AppColors.accent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Módulo 1 · Flutter + Material 3',
                      style: tt.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Card de entorno
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADO DEL ENTORNO',
                      style: tt.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...[
                      ('Flutter', '3.x'),
                      ('Dart', '3.x'),
                      ('Riverpod', '2.x'),
                      ('GoRouter', '14.x'),
                      ('Dio', '5.x'),
                      ('API URL', AppConfig.baseUrl),
                    ].map((item) => _EnvRow(label: item.$1, value: item.$2)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Paleta de colores
              Text(
                'DESIGN SYSTEM',
                style: tt.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ('Accent', AppColors.accent),
                  ('Success', AppColors.success),
                  ('Warning', AppColors.warning),
                  ('Error', AppColors.error),
                  ('Info', AppColors.info),
                ]
                    .map((item) => Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 44,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: item.$2,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.$1,
                                style: const TextStyle(
                                    fontSize: 9, color: AppColors.textFaint),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvRow extends StatelessWidget {
  final String label;
  final String value;
  const _EnvRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
