// lib/presentation/widgets/factura_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../domain/model/factura.dart';
import '../providers/facturas_admin_provider.dart';

void showFacturaForm(BuildContext context, {Factura? factura}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FacturaForm(factura: factura),
  );
}

class _FacturaForm extends ConsumerStatefulWidget {
  final Factura? factura;
  const _FacturaForm({this.factura});

  @override
  ConsumerState<_FacturaForm> createState() => _FacturaFormState();
}

class _FacturaFormState extends ConsumerState<_FacturaForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idVentaCtrl;
  late final TextEditingController _numeroFacturaCtrl;
  late final TextEditingController _subtotalCtrl;
  late final TextEditingController _ivaCtrl;
  late final TextEditingController _totalCtrl;

  DateTime? _fechaEmision;

  bool get _isEditing => widget.factura != null;

  @override
  void initState() {
    super.initState();
    final f = widget.factura;
    _idVentaCtrl =
        TextEditingController(text: f != null ? f.idVenta.toString() : '');
    _numeroFacturaCtrl =
        TextEditingController(text: f?.numeroFactura ?? '');
    _subtotalCtrl = TextEditingController(
        text: f != null ? f.subtotal.toStringAsFixed(2) : '');
    _ivaCtrl = TextEditingController(
        text: f != null ? f.iva.toStringAsFixed(2) : '');
    _totalCtrl = TextEditingController(
        text: f != null ? f.total.toStringAsFixed(2) : '');
    _fechaEmision = f?.fechaEmision;
  }

  @override
  void dispose() {
    _idVentaCtrl.dispose();
    _numeroFacturaCtrl.dispose();
    _subtotalCtrl.dispose();
    _ivaCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  void _calcularTotal() {
    final sub = double.tryParse(_subtotalCtrl.text) ?? 0;
    final iva = double.tryParse(_ivaCtrl.text) ?? 0;
    _totalCtrl.text = (sub + iva).toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(facturasAdminProvider.notifier);
    final idVenta = int.tryParse(_idVentaCtrl.text.trim()) ?? 0;
    final subtotal = double.tryParse(_subtotalCtrl.text.trim()) ?? 0;
    final iva = double.tryParse(_ivaCtrl.text.trim()) ?? 0;
    final total = double.tryParse(_totalCtrl.text.trim()) ?? 0;

    if (_isEditing) {
      await notifier.actualizarFactura(
        idFactura: widget.factura!.idFactura,
        idVenta: idVenta,
        numeroFactura: _numeroFacturaCtrl.text,
        subtotal: subtotal,
        iva: iva,
        total: total,
        fechaEmision: _fechaEmision,
      );
    } else {
      await notifier.crearFactura(
        idVenta: idVenta,
        numeroFactura: _numeroFacturaCtrl.text,
        subtotal: subtotal,
        iva: iva,
        total: total,
        fechaEmision: _fechaEmision,
      );
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEmision ?? DateTime.now(),
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
    if (picked != null) setState(() => _fechaEmision = picked);
  }

  String _formatFecha(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FacturasAdminState>(facturasAdminProvider, (prev, next) {
      if (next.formState is FacturaFormSuccess) {
        final msg = (next.formState as FacturaFormSuccess).message;
        ref.read(facturasAdminProvider.notifier).resetFormState();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
      }
    });

    final formState = ref.watch(facturasAdminProvider).formState;
    final isSaving = formState is FacturaFormSaving;
    final formError =
        formState is FacturaFormError ? (formState).message : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
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
                      _isEditing ? 'Editar Factura' : 'Nueva Factura',
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
              _buildLabel('ID Venta *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _idVentaCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDec('Ej: 1'),
                validator: (v) {
                  final val = int.tryParse(v?.trim() ?? '');
                  return val == null || val <= 0
                      ? 'Ingresa un ID de venta válido'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Número de factura *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _numeroFacturaCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLength: 50,
                decoration: _inputDec('Ej: FAC-2024-001'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Subtotal *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _subtotalCtrl,
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _inputDec('0.00'),
                          onChanged: (_) => _calcularTotal(),
                          validator: (v) {
                            final val = double.tryParse(v?.trim() ?? '');
                            return val == null || val < 0
                                ? 'Valor inválido'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('IVA *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _ivaCtrl,
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _inputDec('0.00'),
                          onChanged: (_) => _calcularTotal(),
                          validator: (v) {
                            final val = double.tryParse(v?.trim() ?? '');
                            return val == null || val < 0
                                ? 'Valor inválido'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabel('Total *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _totalCtrl,
                style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.bold),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDec('0.00'),
                validator: (v) {
                  final val = double.tryParse(v?.trim() ?? '');
                  return val == null || val < 0 ? 'Valor inválido' : null;
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Fecha de emisión (opcional)'),
              const SizedBox(height: 6),
              _DateSelector(
                fecha: _fechaEmision,
                onTap: _seleccionarFecha,
                onClear: () => setState(() => _fechaEmision = null),
                label: _formatFecha(_fechaEmision),
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
                          _isEditing ? 'Actualizar factura' : 'Crear factura',
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

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

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

// ── Widgets compartidos reutilizables ─────────────────────────────────────────

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
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(message,
          style: const TextStyle(color: AppColors.error, fontSize: 13)),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime? fecha;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final String label;

  const _DateSelector({
    required this.fecha,
    required this.onTap,
    required this.onClear,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: fecha != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            if (fecha != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    color: AppColors.textSecondary, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
