// lib/presentation/widgets/seguro_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/seguro.dart';
import '../../theme/app_colors.dart';
import '../providers/seguros_admin_provider.dart';

void showSeguroForm(BuildContext context, {Seguro? seguro}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SeguroForm(seguro: seguro),
  );
}

class _SeguroForm extends ConsumerStatefulWidget {
  final Seguro? seguro;
  const _SeguroForm({this.seguro});

  @override
  ConsumerState<_SeguroForm> createState() => _SeguroFormState();
}

class _SeguroFormState extends ConsumerState<_SeguroForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idVentaCtrl;
  late final TextEditingController _aseguradoraCtrl;
  late final TextEditingController _polizaCtrl;
  late final TextEditingController _costoCtrl;

  String _tipoCobertura = TipoCobertura.basica.value;
  String _estado = EstadoSeguro.pendiente.value;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  bool get _isEditing => widget.seguro != null;

  @override
  void initState() {
    super.initState();
    final s = widget.seguro;
    _idVentaCtrl =
        TextEditingController(text: s != null ? s.idVenta.toString() : '');
    _aseguradoraCtrl = TextEditingController(text: s?.aseguradora ?? '');
    _polizaCtrl = TextEditingController(text: s?.numeroPoliza ?? '');
    _costoCtrl = TextEditingController(
        text: s != null ? s.costoAnual.toStringAsFixed(2) : '');
    _tipoCobertura = s?.tipoCobertura.value ?? TipoCobertura.basica.value;
    _estado = s?.estado.value ?? EstadoSeguro.pendiente.value;
    _fechaInicio = s?.fechaInicio;
    _fechaFin = s?.fechaFin;
  }

  @override
  void dispose() {
    _idVentaCtrl.dispose();
    _aseguradoraCtrl.dispose();
    _polizaCtrl.dispose();
    _costoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(segurosAdminProvider.notifier);
    final idVenta = int.tryParse(_idVentaCtrl.text.trim()) ?? 0;
    final costo = double.tryParse(_costoCtrl.text.trim()) ?? 0;

    if (_isEditing) {
      await notifier.actualizarSeguro(
        idSeguro: widget.seguro!.idSeguro,
        idVenta: idVenta,
        aseguradora: _aseguradoraCtrl.text,
        numeroPoliza: _polizaCtrl.text,
        tipoCobertura: _tipoCobertura,
        costoAnual: costo,
        estado: _estado,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
    } else {
      await notifier.crearSeguro(
        idVenta: idVenta,
        aseguradora: _aseguradoraCtrl.text,
        numeroPoliza: _polizaCtrl.text,
        tipoCobertura: _tipoCobertura,
        costoAnual: costo,
        estado: _estado,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
    }
  }

  Future<void> _selectDate({required bool isInicio}) async {
    final current = isInicio ? _fechaInicio : _fechaFin;
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
        if (isInicio) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
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
    ref.listen<SegurosAdminState>(segurosAdminProvider, (prev, next) {
      if (next.formState is SeguroFormSuccess) {
        final msg = (next.formState as SeguroFormSuccess).message;
        ref.read(segurosAdminProvider.notifier).resetFormState();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
      }
    });

    final formState = ref.watch(segurosAdminProvider).formState;
    final isSaving = formState is SeguroFormSaving;
    final formError =
        formState is SeguroFormError ? (formState).message : null;

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
                      _isEditing ? 'Editar Seguro' : 'Nuevo Seguro',
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
              _FieldGroup(
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
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Aseguradora *',
                child: TextFormField(
                  controller: _aseguradoraCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  maxLength: 100,
                  decoration: _inputDec('Ej: Seguros Bolívar'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                ),
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Número de póliza *',
                child: TextFormField(
                  controller: _polizaCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  maxLength: 100,
                  decoration: _inputDec('Ej: POL-2024-0001'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _FieldGroup(
                      label: 'Tipo cobertura *',
                      child: DropdownButtonFormField<String>(
                        value: _tipoCobertura,
                        dropdownColor: AppColors.surface2,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        isExpanded: true,
                        decoration: _inputDec(null),
                        items: TipoCobertura.values
                            .map((t) => DropdownMenuItem(
                                  value: t.value,
                                  child: Text(t.label,
                                      style: TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _tipoCobertura = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldGroup(
                      label: 'Estado *',
                      child: DropdownButtonFormField<String>(
                        value: _estado,
                        dropdownColor: AppColors.surface2,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        isExpanded: true,
                        decoration: _inputDec(null),
                        items: EstadoSeguro.values
                            .map((e) => DropdownMenuItem(
                                  value: e.value,
                                  child: Text(e.label,
                                      style: TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _estado = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Costo anual *',
                child: TextFormField(
                  controller: _costoCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDec('Ej: 850.00'),
                  validator: (v) {
                    final val = double.tryParse(v?.trim() ?? '');
                    return val == null || val < 0 ? 'Valor inválido' : null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _FieldGroup(
                      label: 'Fecha inicio',
                      child: _DateBtn(
                        label: _formatFecha(_fechaInicio),
                        hasValue: _fechaInicio != null,
                        onTap: () => _selectDate(isInicio: true),
                        onClear: () => setState(() => _fechaInicio = null),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldGroup(
                      label: 'Fecha fin',
                      child: _DateBtn(
                        label: _formatFecha(_fechaFin),
                        hasValue: _fechaFin != null,
                        onTap: () => _selectDate(isInicio: false),
                        onClear: () => setState(() => _fechaFin = null),
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
                          _isEditing ? 'Actualizar seguro' : 'Registrar seguro',
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
