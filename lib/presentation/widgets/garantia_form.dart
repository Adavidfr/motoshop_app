// lib/presentation/widgets/garantia_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/garantia.dart';
import '../../theme/app_colors.dart';
import '../providers/garantias_admin_provider.dart';

void showGarantiaForm(BuildContext context, {Garantia? garantia}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GarantiaForm(garantia: garantia),
  );
}

class _GarantiaForm extends ConsumerStatefulWidget {
  final Garantia? garantia;
  const _GarantiaForm({this.garantia});

  @override
  ConsumerState<_GarantiaForm> createState() => _GarantiaFormState();
}

class _GarantiaFormState extends ConsumerState<_GarantiaForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idVentaCtrl;
  late final TextEditingController _idMotoCtrl;
  late final TextEditingController _mesesCtrl;
  late final TextEditingController _descripcionCtrl;

  String _estado = EstadoGarantia.activa.value;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  bool get _isEditing => widget.garantia != null;

  @override
  void initState() {
    super.initState();
    final g = widget.garantia;
    _idVentaCtrl =
        TextEditingController(text: g != null ? g.idVenta.toString() : '');
    _idMotoCtrl =
        TextEditingController(text: g != null ? g.idMoto.toString() : '');
    _mesesCtrl = TextEditingController(
        text: g != null ? g.mesesGarantia.toString() : '');
    _descripcionCtrl =
        TextEditingController(text: g?.descripcion ?? '');
    _estado = g?.estado.value ?? EstadoGarantia.activa.value;
    _fechaInicio = g?.fechaInicio;
    _fechaFin = g?.fechaFin;
  }

  @override
  void dispose() {
    _idVentaCtrl.dispose();
    _idMotoCtrl.dispose();
    _mesesCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(garantiasAdminProvider.notifier);

    if (_isEditing) {
      await notifier.actualizarGarantia(
        idGarantia: widget.garantia!.idGarantia,
        idVenta: int.tryParse(_idVentaCtrl.text.trim()) ?? 0,
        idMoto: int.tryParse(_idMotoCtrl.text.trim()) ?? 0,
        mesesGarantia: int.tryParse(_mesesCtrl.text.trim()) ?? 0,
        estado: _estado,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        descripcion: _descripcionCtrl.text,
      );
    } else {
      await notifier.crearGarantia(
        idVenta: int.tryParse(_idVentaCtrl.text.trim()) ?? 0,
        idMoto: int.tryParse(_idMotoCtrl.text.trim()) ?? 0,
        mesesGarantia: int.tryParse(_mesesCtrl.text.trim()) ?? 0,
        estado: _estado,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        descripcion: _descripcionCtrl.text,
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
    ref.listen<GarantiasAdminState>(garantiasAdminProvider, (prev, next) {
      if (next.formState is GarantiaFormSuccess) {
        final msg = (next.formState as GarantiaFormSuccess).message;
        ref.read(garantiasAdminProvider.notifier).resetFormState();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
      }
    });

    final formState = ref.watch(garantiasAdminProvider).formState;
    final isSaving = formState is GarantiaFormSaving;
    final formError =
        formState is GarantiaFormError ? (formState).message : null;

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
                      _isEditing ? 'Editar Garantía' : 'Nueva Garantía',
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _inputDec('Ej: 1'),
                        validator: (v) {
                          final val = int.tryParse(v?.trim() ?? '');
                          return val == null || val <= 0
                              ? 'ID inválido'
                              : null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldGroup(
                      label: 'ID Moto *',
                      child: TextFormField(
                        controller: _idMotoCtrl,
                        style: TextStyle(color: AppColors.textPrimary),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _inputDec('Ej: 5'),
                        validator: (v) {
                          final val = int.tryParse(v?.trim() ?? '');
                          return val == null || val <= 0
                              ? 'ID inválido'
                              : null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Meses de garantía *',
                child: TextFormField(
                  controller: _mesesCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDec('Ej: 12'),
                  validator: (v) {
                    final val = int.tryParse(v?.trim() ?? '');
                    return val == null || val <= 0
                        ? 'Ingresa los meses de garantía'
                        : null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Estado *',
                child: DropdownButtonFormField<String>(
                  value: _estado,
                  dropdownColor: AppColors.surface2,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDec(null),
                  items: EstadoGarantia.values
                      .map((e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.label),
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
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Descripción (opcional)',
                child: TextFormField(
                  controller: _descripcionCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: _inputDec('Descripción de la garantía…'),
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
                          _isEditing
                              ? 'Actualizar garantía'
                              : 'Registrar garantía',
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
      );
}

// ── Widgets auxiliares compartidos ────────────────────────────────────────────

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
