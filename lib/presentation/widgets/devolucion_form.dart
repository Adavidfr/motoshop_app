// lib/presentation/widgets/devolucion_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/devolucion.dart';
import '../../theme/app_colors.dart';
import '../providers/devoluciones_admin_provider.dart';

void showDevolucionForm(BuildContext context, {Devolucion? devolucion}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DevolucionForm(devolucion: devolucion),
  );
}

class _DevolucionForm extends ConsumerStatefulWidget {
  final Devolucion? devolucion;
  const _DevolucionForm({this.devolucion});

  @override
  ConsumerState<_DevolucionForm> createState() => _DevolucionFormState();
}

class _DevolucionFormState extends ConsumerState<_DevolucionForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idVentaCtrl;
  late final TextEditingController _motivoCtrl;
  late final TextEditingController _montoCtrl;

  String _estado = EstadoDevolucion.pendiente.value;
  DateTime? _fechaSolicitud;
  DateTime? _fechaResolucion;

  bool get _isEditing => widget.devolucion != null;

  @override
  void initState() {
    super.initState();
    final d = widget.devolucion;
    _idVentaCtrl =
        TextEditingController(text: d != null ? d.idVenta.toString() : '');
    _motivoCtrl = TextEditingController(text: d?.motivo ?? '');
    _montoCtrl = TextEditingController(
        text: d != null ? d.montoDevolucion.toStringAsFixed(2) : '');
    _estado = d?.estado.value ?? EstadoDevolucion.pendiente.value;
    _fechaSolicitud = d?.fechaSolicitud;
    _fechaResolucion = d?.fechaResolucion;
  }

  @override
  void dispose() {
    _idVentaCtrl.dispose();
    _motivoCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(devolucionesAdminProvider.notifier);
    final idVenta = int.tryParse(_idVentaCtrl.text.trim()) ?? 0;
    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0;

    if (_isEditing) {
      await notifier.actualizarDevolucion(
        idDevolucion: widget.devolucion!.idDevolucion,
        idVenta: idVenta,
        motivo: _motivoCtrl.text,
        estadoDev: _estado,
        montoDevolucion: monto,
        fechaSolicitud: _fechaSolicitud,
        fechaResolucion: _fechaResolucion,
      );
    } else {
      await notifier.crearDevolucion(
        idVenta: idVenta,
        motivo: _motivoCtrl.text,
        estadoDev: _estado,
        montoDevolucion: monto,
        fechaSolicitud: _fechaSolicitud,
        fechaResolucion: _fechaResolucion,
      );
    }
  }

  Future<void> _selectDate({required bool isSolicitud}) async {
    final current = isSolicitud ? _fechaSolicitud : _fechaResolucion;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
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
        if (isSolicitud) {
          _fechaSolicitud = picked;
        } else {
          _fechaResolucion = picked;
        }
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
    ref.listen<DevolucionesAdminState>(devolucionesAdminProvider, (prev, next) {
      if (next.formState is DevolucionFormSuccess) {
        final msg = (next.formState as DevolucionFormSuccess).message;
        ref.read(devolucionesAdminProvider.notifier).resetFormState();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
      }
    });

    final formState = ref.watch(devolucionesAdminProvider).formState;
    final isSaving = formState is DevolucionFormSaving;
    final formError =
        formState is DevolucionFormError ? (formState).message : null;

    return Container(
      decoration: const BoxDecoration(
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
                      _isEditing ? 'Editar Devolución' : 'Nueva Devolución',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
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
                        style: const TextStyle(color: AppColors.textPrimary),
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
                      label: 'Monto a Devolver *',
                      child: TextFormField(
                        controller: _montoCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDec('Ej: 150.00'),
                        validator: (v) {
                          final val = double.tryParse(v?.trim() ?? '');
                          return val == null || val < 0 ? 'Monto inválido' : null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Motivo *',
                child: TextFormField(
                  controller: _motivoCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: _inputDec('Descripción del motivo...'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Estado',
                child: DropdownButtonFormField<String>(
                  value: _estado,
                  dropdownColor: AppColors.surface2,
                  style:
                      const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  isExpanded: true,
                  decoration: _inputDec(null),
                  items: EstadoDevolucion.values
                      .map((e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.label,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _estado = v);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _FieldGroup(
                      label: 'Fecha Solicitud',
                      child: _DateBtn(
                        label: _formatFecha(_fechaSolicitud),
                        hasValue: _fechaSolicitud != null,
                        onTap: () => _selectDate(isSolicitud: true),
                        onClear: () => setState(() => _fechaSolicitud = null),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldGroup(
                      label: 'Fecha Resolución',
                      child: _DateBtn(
                        label: _formatFecha(_fechaResolucion),
                        hasValue: _fechaResolucion != null,
                        onTap: () => _selectDate(isSolicitud: false),
                        onClear: () => setState(() => _fechaResolucion = null),
                      ),
                    ),
                  ),
                ],
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
                          _isEditing ? 'Actualizar' : 'Registrar',
                          style: const TextStyle(
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
        hintStyle: const TextStyle(color: AppColors.textFaint),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        errorStyle: const TextStyle(color: AppColors.error),
        counterStyle: const TextStyle(color: AppColors.textFaint),
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
          style: const TextStyle(color: AppColors.error, fontSize: 13)),
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
          style: const TextStyle(
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
            const Icon(Icons.calendar_today_outlined,
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
                child: const Icon(Icons.close,
                    color: AppColors.textSecondary, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}
