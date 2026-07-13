import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motoshop_app/domain/model/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _cedulaCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _fechaNacCtrl;

  bool _isEditing = false;
  File? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    _cedulaCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();
    _fechaNacCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _fechaNacCtrl.dispose();
    super.dispose();
  }

  void _populateFields(UserProfile? profile) {
    if (profile == null) return;
    _cedulaCtrl.text = profile.cedula;
    _telefonoCtrl.text = profile.telefono;
    _direccionCtrl.text = profile.direccion;
    _fechaNacCtrl.text = profile.fechaNacimiento ?? '';
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _selectedImageFile = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final profileState = ref.watch(profileProvider);
    final tt = Theme.of(context).textTheme;

    // Popular campos si no se está editando y los datos se cargaron
    if (!_isEditing && profileState.profile != null) {
      _populateFields(profileState.profile);
    }

    ref.listen<ProfileFormState>(
      profileProvider.select((s) => s.formState),
      (_, next) {
        if (next is ProfileFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.accent),
          );
          ref.read(profileProvider.notifier).resetFormState();
          setState(() {
            _isEditing = false;
            _selectedImageFile = null;
          });
        } else if (next is ProfileFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.error),
          );
          ref.read(profileProvider.notifier).resetFormState();
        }
      },
    );

    final isSaving = profileState.formState is ProfileFormSaving;
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeProvider)
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            tooltip: 'Cambiar Tema',
          ),
          if (!_isEditing && profile != null)
            IconButton(
              icon: Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Editar Perfil',
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => setState(() {
                _isEditing = false;
                _selectedImageFile = null;
              }),
              tooltip: 'Cancelar Edición',
            ),
        ],
      ),
      body: SafeArea(
        child: profileState.isLoading && profile == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Avatar & Picker
                    Center(
                      child: GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.border, width: 2),
                              ),
                              child: ClipOval(
                                child: _selectedImageFile != null
                                    ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                                    : (profile?.fotoPerfil != null
                                        ? Image.network(
                                            profile!.fotoPerfil!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, o, s) =>
                                                Icon(Icons.person, size: 60),
                                          )
                                        : Icon(Icons.person, size: 60)),
                              ),
                            ),
                            if (_isEditing)
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.accent,
                                child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user?.username ?? '—', style: tt.headlineMedium),
                    Text(user?.email ?? '—', style: tt.bodyMedium),
                    const SizedBox(height: 8),
                    if (user?.isStaff == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Staff / Administrador',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

                    Form(
                      key: _formKey,
                      child: Container(
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
                              'INFORMACIÓN DE CLIENTE',
                              style: tt.labelSmall?.copyWith(
                                letterSpacing: 1.2,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cedulaCtrl,
                              decoration: const InputDecoration(labelText: 'Cédula / RUC'),
                              enabled: _isEditing && !isSaving,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _telefonoCtrl,
                              decoration: const InputDecoration(labelText: 'Teléfono'),
                              enabled: _isEditing && !isSaving,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _direccionCtrl,
                              decoration: const InputDecoration(labelText: 'Dirección'),
                              maxLines: 2,
                              enabled: _isEditing && !isSaving,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fechaNacCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Fecha de Nacimiento (AAAA-MM-DD)',
                                hintText: 'Ej. 1995-10-25',
                              ),
                              enabled: _isEditing && !isSaving,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return null;
                                final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                                if (!regex.hasMatch(val)) return 'Formato debe ser AAAA-MM-DD';
                                return null;
                              },
                            ),
                            if (_isEditing) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isSaving ? null : _onSave,
                                  child: isSaving
                                      ? const CircularProgressIndicator()
                                      : const Text('Guardar Cambios'),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Admin view list navigate button
                    if (user?.isStaff == true) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/admin'),
                          icon: Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Panel de Usuarios (Admin)'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Client Financing Button
                    if (user?.isStaff != true) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/financiamientos'),
                          icon: Icon(Icons.credit_card_outlined),
                          label: const Text('Mis Planes de Financiamiento'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.accent,
                            side: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Logout Button
                    _LogoutButton(
                      onConfirm: () async {
                        await ref.read(authProvider.notifier).logout();
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(profileProvider.notifier).updateProfile(
          cedula: _cedulaCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
          direccion: _direccionCtrl.text.trim(),
          fechaNacimiento: _fechaNacCtrl.text.trim().isEmpty ? null : _fechaNacCtrl.text.trim(),
          fotoFile: _selectedImageFile,
        );
  }
}

class _LogoutButton extends StatelessWidget {
  final Future<void> Function() onConfirm;
  const _LogoutButton({required this.onConfirm});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('¿Cerrar sesión?', style: TextStyle(color: AppColors.textPrimary)),
              content: const Text(
                'Tu sesión se cerrará en este dispositivo.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await Future.delayed(const Duration(milliseconds: 100));
                    await onConfirm();
                  },
                  child: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          icon: Icon(Icons.logout, color: AppColors.error),
          label: const Text('Cerrar sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
          ),
        ),
      );
}
