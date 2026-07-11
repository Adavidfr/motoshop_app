// lib/presentation/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/forgotpasswordprovider.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(forgotPasswordProvider);
    final isSent    = state is ForgotPasswordSuccess;
    final isLoading = state is ForgotPasswordLoading;
    final error     = switch (state) {
      ForgotPasswordError(:final message) => message,
      _ => null,
    };
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:           const Text('Recuperar contraseña'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation:       0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              if (!isSent) ...[
                // ── Formulario de solicitud ───────────────────────────
                Icon(Icons.email_outlined, size: 64, color: AppColors.accent),
                const SizedBox(height: 24),
                Text(
                  'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color:        AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      if (error != null) ...[
                        Container(
                          width:   double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:        AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border:       Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            error,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AuthTextField(
                        label:        'Correo electrónico',
                        hint:         'tu@email.com',
                        controller:   _emailCtrl,
                        enabled:      !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) =>
                            ref.read(forgotPasswordProvider.notifier).clearError(),
                      ),
                      const SizedBox(height: 24),
                      ListenableBuilder(
                        listenable: _emailCtrl,
                        builder: (_, __) => AuthButton(
                          label:     'Enviar enlace',
                          onPressed: _emailCtrl.text.trim().isEmpty
                              ? null
                              : () => ref
                                  .read(forgotPasswordProvider.notifier)
                                  .requestReset(_emailCtrl.text),
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // ── Confirmación de envío ─────────────────────────────
                Icon(
                  Icons.mark_email_read_outlined,
                  size:  64,
                  color: AppColors.success,
                ),
                const SizedBox(height: 24),
                Text(
                  'Revisa tu correo',
                  style: tt.headlineSmall?.copyWith(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Si el correo está registrado, recibirás el enlace en unos minutos.\n\n'
                  'Abre el enlace del correo, copia el uid y el token, y úsalos en el siguiente paso.',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.push('/reset-password-confirm'),
                    child: const Text('Tengo el código → Restablecer contraseña'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}