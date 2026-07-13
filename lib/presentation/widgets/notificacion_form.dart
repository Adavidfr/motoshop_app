// lib/presentation/widgets/notificacion_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/notificacion.dart';
import '../../theme/app_colors.dart';
import '../providers/notificaciones_admin_provider.dart';

void showNotificacionForm(BuildContext context, {Notificacion? notificacion}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotificacionForm(notificacion: notificacion),
  );
}

class _NotificacionForm extends ConsumerStatefulWidget {
  final Notificacion? notificacion;
  const _NotificacionForm({this.notificacion});

  @override
  ConsumerState<_NotificacionForm> createState() => _NotificacionFormState();
}

class _NotificacionFormState extends ConsumerState<_NotificacionForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idUsuarioCtrl;
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _mensajeCtrl;

  bool _leido = false;
  DateTime? _fechaCreacion;

  bool get _isEditing => widget.notificacion != null;

  @override
  void initState() {
    super.initState();
    final n = widget.notificacion;
    _idUsuarioCtrl =
        TextEditingController(text: n != null ? n.idUsuario.toString() : '');
    _tituloCtrl = TextEditingController(text: n?.titulo ?? '');
    _mensajeCtrl = TextEditingController(text: n?.mensaje ?? '');
    _leido = n?.leido ?? false;
    _fechaCreacion = n?.fechaCreacion;
  }

  @override
  void dispose() {
    _idUsuarioCtrl.dispose();
    _tituloCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(notificacionesAdminProvider.notifier);
    final idUsuario = int.tryParse(_idUsuarioCtrl.text.trim()) ?? 0;

    if (_isEditing) {
      await notifier.actualizarNotificacion(
        idNotificacion: widget.notificacion!.idNotificacion,
        idUsuario: idUsuario,
        titulo: _tituloCtrl.text,
        mensaje: _mensajeCtrl.text,
        leido: _leido,
        fechaCreacion: _fechaCreacion,
      );
    } else {
      await notifier.crearNotificacion(
        idUsuario: idUsuario,
        titulo: _tituloCtrl.text,
        mensaje: _mensajeCtrl.text,
        leido: _leido,
        fechaCreacion: _fechaCreacion,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NotificacionesAdminState>(notificacionesAdminProvider,
        (prev, next) {
      if (next.formState is NotificacionFormSuccess) {
        final msg = (next.formState as NotificacionFormSuccess).message;
        ref.read(notificacionesAdminProvider.notifier).resetFormState();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
      }
    });

    final formState = ref.watch(notificacionesAdminProvider).formState;
    final isSaving = formState is NotificacionFormSaving;
    final formError =
        formState is NotificacionFormError ? (formState).message : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar Notificación' : 'Nueva Notificación',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (formError != null) ...[
                _ErrorBanner(message: formError),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _FieldGroup(
                      label: 'ID Usuario *',
                      child: TextFormField(
                        controller: _idUsuarioCtrl,
                        style: TextStyle(color: AppColors.textPrimary),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _inputDec('Ej: 1'),
                        validator: (v) {
                          final val = int.tryParse(v?.trim() ?? '');
                          return val == null || val <= 0 ? 'ID inválido' : null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estado',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          value: _leido,
                          onChanged: (v) => setState(() => _leido = v),
                          title: Text(
                            _leido ? 'Leído' : 'No leído',
                            style: TextStyle(
                              color: _leido
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          activeColor: AppColors.accent,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Título *',
                child: TextFormField(
                  controller: _tituloCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  maxLength: 150,
                  decoration: _inputDec('Ej: Alerta de mantenimiento'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Mensaje *',
                child: TextFormField(
                  controller: _mensajeCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  maxLines: 4,
                  decoration: _inputDec('Cuerpo del mensaje...'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onAccent,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Actualizar' : 'Enviar Notificación',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textFaint),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error),
        ),
        errorStyle: TextStyle(color: AppColors.error),
        counterStyle: TextStyle(color: AppColors.textFaint),
      );
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(message,
          style: TextStyle(color: AppColors.error, fontSize: 13)),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
