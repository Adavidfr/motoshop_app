// lib/presentation/widgets/historial_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../providers/historial_estado_venta_provider.dart';

void showHistorialForm(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HistorialForm(),
  );
}

class _HistorialForm extends ConsumerStatefulWidget {
  const _HistorialForm();

  @override
  ConsumerState<_HistorialForm> createState() => _HistorialFormState();
}

class _HistorialFormState extends ConsumerState<_HistorialForm> {
  final _formKey = GlobalKey<FormState>();

  final _idVentaCtrl = TextEditingController();
  final _estadoAnteriorCtrl = TextEditingController();
  final _estadoNuevoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  DateTime? _fechaCambio;

  @override
  void dispose() {
    _idVentaCtrl.dispose();
    _estadoAnteriorCtrl.dispose();
    _estadoNuevoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(historialEstadoVentaProvider.notifier);
    final idVenta = int.tryParse(_idVentaCtrl.text.trim()) ?? 0;

    await notifier.registrarCambio(
      idVenta: idVenta,
      estadoNuevo: _estadoNuevoCtrl.text,
      estadoAnterior: _estadoAnteriorCtrl.text,
      observacion: _obsCtrl.text,
      fechaCambio: _fechaCambio,
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaCambio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.surface2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _fechaCambio = picked;
      });
    }
  }

  String _formatFecha(DateTime? date) {
    if (date == null) return 'Seleccionar';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<HistorialEstadoVentaState>(historialEstadoVentaProvider,
        (prev, next) {
      if (next.formState is HistorialFormSuccess) {
        final msg = (next.formState as HistorialFormSuccess).message;
        ref.read(historialEstadoVentaProvider.notifier).resetFormState();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
      }
    });

    final formState = ref.watch(historialEstadoVentaProvider).formState;
    final isSaving = formState is HistorialFormSaving;
    final formError =
        formState is HistorialFormError ? (formState).message : null;

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
                  const Expanded(
                    child: Text(
                      'Registrar Cambio de Estado',
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
                    child: _FieldGroup(
                      label: 'ID Venta *',
                      child: TextFormField(
                        controller: _idVentaCtrl,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldGroup(
                      label: 'Fecha cambio',
                      child: _DateBtn(
                        label: _formatFecha(_fechaCambio),
                        hasValue: _fechaCambio != null,
                        onTap: _selectDate,
                        onClear: () => setState(() => _fechaCambio = null),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _FieldGroup(
                      label: 'Estado Anterior',
                      child: TextFormField(
                        controller: _estadoAnteriorCtrl,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDec('Ej: Pendiente'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldGroup(
                      label: 'Estado Nuevo *',
                      child: TextFormField(
                        controller: _estadoNuevoCtrl,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDec('Ej: Completada'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Observación',
                child: TextFormField(
                  controller: _obsCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: _inputDec('Comentarios adicionales...'),
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
                      : const Text(
                          'Registrar Cambio',
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

class _DateBtn extends StatelessWidget {
  final String label;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateBtn({
    required this.label,
    required this.hasValue,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      hasValue ? AppColors.textPrimary : AppColors.textFaint,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close,
                    color: AppColors.textSecondary, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}
