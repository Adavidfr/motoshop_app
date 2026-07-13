// lib/presentation/screens/auth/reset_password_confirm_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../providers/reset_password_provider.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/auth_text_field.dart';

class ResetPasswordConfirmScreen extends ConsumerStatefulWidget {
  const ResetPasswordConfirmScreen({super.key});

  @override
  ConsumerState<ResetPasswordConfirmScreen> createState() =>
      _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState
    extends ConsumerState<ResetPasswordConfirmScreen> {
  final _uidCtrl   = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _pass1Ctrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool  _showPass  = false;

  @override
  void dispose() {
    _uidCtrl.dispose();
    _tokenCtrl.dispose();
    _pass1Ctrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  bool get _passwordMismatch =>
      _pass2Ctrl.text.isNotEmpty && _pass1Ctrl.text != _pass2Ctrl.text;

  bool get _isFormValid =>
      _uidCtrl.text.isNotEmpty &&
      _tokenCtrl.text.isNotEmpty &&
      _pass1Ctrl.text.isNotEmpty &&
      !_passwordMismatch;

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(resetPasswordProvider);
    final isLoading = state is ResetPasswordLoading;
    final error     = switch (state) {
      ResetPasswordError(:final message) => message,
      _ => null,
    };
    final tt = Theme.of(context).textTheme;

    ref.listen<ResetPasswordState>(resetPasswordProvider, (_, next) {
      if (next is ResetPasswordSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada. Inicia sesión.'),
          ),
        );
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:           const Text('Nueva contraseña'),
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
              const SizedBox(height: 32),
              Icon(Icons.lock_outline, size: 48, color: AppColors.accent),
              const SizedBox(height: 12),
              Text(
                'Pega el uid y el token del enlace que recibiste por correo y elige una nueva contraseña.',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:        AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: AppColors.border),
                ),
                child: ListenableBuilder(
                  listenable: Listenable.merge(
                      [_uidCtrl, _tokenCtrl, _pass1Ctrl, _pass2Ctrl]),
                  builder: (_, __) => Column(
                    children: [
                      if (error != null) ...[
                        Container(
                          width:   double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:        AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            error,
                            style: TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AuthTextField(
                        label:      'UID',
                        hint:       'ej. MQ',
                        controller: _uidCtrl,
                        enabled:    !isLoading,
                        onChanged: (_) =>
                            ref.read(resetPasswordProvider.notifier).clearError(),
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        label:      'Token',
                        hint:       'ej. abc-defg-hij',
                        controller: _tokenCtrl,
                        enabled:    !isLoading,
                        onChanged: (_) =>
                            ref.read(resetPasswordProvider.notifier).clearError(),
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        label:      'Nueva contraseña',
                        hint:       '••••••••',
                        controller: _pass1Ctrl,
                        isPassword: !_showPass,
                        enabled:    !isLoading,
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        label:      'Confirmar contraseña',
                        hint:       '••••••••',
                        controller: _pass2Ctrl,
                        isPassword: !_showPass,
                        enabled:    !isLoading,
                        errorText:  _passwordMismatch
                            ? 'Las contraseñas no coinciden'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value:    _showPass,
                            onChanged: isLoading
                                ? null
                                : (v) =>
                                    setState(() => _showPass = v ?? false),
                            activeColor: AppColors.accent,
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () =>
                                    setState(() => _showPass = !_showPass),
                            child: const Text(
                              'Mostrar contraseñas',
                              style: TextStyle(
                                  color:    AppColors.textSecondary,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AuthButton(
                        label:     'Restablecer contraseña',
                        onPressed: _isFormValid
                            ? () => ref
                                .read(resetPasswordProvider.notifier)
                                .confirmReset(
                                  uid:          _uidCtrl.text,
                                  token:        _tokenCtrl.text,
                                  newPassword:  _pass1Ctrl.text,
                                  newPassword2: _pass2Ctrl.text,
                                )
                            : null,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}