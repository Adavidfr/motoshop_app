// lib/presentation/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/model/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          _userCtrl.text,
          _passCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isChecking;
    final error = authState.error;
    final tt = Theme.of(context).textTheme;

    // Escuchar cambios de estado para navegar
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated) {
        final dest = next.isStaff ? '/admin' : '/';
        context.go(dest);
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF180405), // Muy profundo tono rojo oscuro
              Color(0xFF000000), // Negro absoluto
            ],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // Logo Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.2),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/logo_transparente.png',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AuraRider',
                    style: tt.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diseño, potencia y control en tus manos',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Card del formulario
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.05),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error general del servidor
                          if (error != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
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

                          // Campo usuario
                          AuthTextField(
                            label: 'Usuario',
                            hint: 'tu_usuario',
                            controller: _userCtrl,
                            enabled: !isLoading,
                            validator: _submitted ? validateUsername : null,
                            onChanged: (_) =>
                                ref.read(authProvider.notifier).clearError(),
                          ),
                          const SizedBox(height: 16),

                          // Campo contraseña
                          AuthTextField(
                            label: 'Contraseña',
                            hint: '••••••••',
                            controller: _passCtrl,
                            isPassword: true,
                            enabled: !isLoading,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            validator: _submitted
                                ? (v) => (v == null || v.isEmpty)
                                    ? 'Campo obligatorio'
                                    : null
                                : null,
                            onChanged: (_) =>
                                ref.read(authProvider.notifier).clearError(),
                          ),
                          const SizedBox(height: 24),

                          // Botón
                          AuthButton(
                            label: 'Iniciar sesión',
                            onPressed: _submit,
                            isLoading: isLoading,
                          ),

                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Link al registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¿No tienes cuenta? ', style: tt.bodyMedium),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Regístrate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
