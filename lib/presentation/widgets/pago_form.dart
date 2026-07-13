// lib/presentation/widgets/pago_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/pago.dart';
import '../../theme/app_colors.dart';
import '../providers/pagos_admin_provider.dart';

// ── Helper para abrir el bottom sheet ────────────────────────────────────────

void showPagoForm(
  BuildContext context, {
  Pago? pago,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PagoForm(pago: pago),
  );
}

// ── Formulario ────────────────────────────────────────────────────────────────

class _PagoForm extends ConsumerStatefulWidget {
  final Pago? pago;

  const _PagoForm({this.pago});

  @override
  ConsumerState<_PagoForm> createState() => _PagoFormState();
}

class _PagoFormState extends ConsumerState<_PagoForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idVentaCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _referenciaCtrl;

  String _metodoPago = MetodoPago.efectivo.value;
  String _estado = EstadoPago.pendiente.value;
  DateTime? _fechaPago;

  bool get _isEditing => widget.pago != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pago;
    _idVentaCtrl =
        TextEditingController(text: p != null ? p.idVenta.toString() : '');
    _montoCtrl = TextEditingController(
        text: p != null ? p.monto.toStringAsFixed(2) : '');
    _referenciaCtrl = TextEditingController(text: p?.referencia ?? '');
    _metodoPago = p?.metodoPago.value ?? MetodoPago.efectivo.value;
    _estado = p?.estado.value ?? EstadoPago.pendiente.value;
    _fechaPago = p?.fechaPago;
  }

  @override
  void dispose() {
    _idVentaCtrl.dispose();
    _montoCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(pagosAdminProvider.notifier);
    final idVenta = int.tryParse(_idVentaCtrl.text.trim()) ?? 0;
    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0;

    if (_isEditing) {
      await notifier.actualizarPago(
        idPago: widget.pago!.idPago,
        idVenta: idVenta,
        monto: monto,
        metodoPago: _metodoPago,
        estado: _estado,
        fechaPago: _fechaPago,
        referencia: _referenciaCtrl.text,
      );
    } else {
      await notifier.crearPago(
        idVenta: idVenta,
        monto: monto,
        metodoPago: _metodoPago,
        estado: _estado,
        fechaPago: _fechaPago,
        referencia: _referenciaCtrl.text,
      );
    }
  }

  // ── Selector de fecha ────────────────────────────────────────────────────

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaPago ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surface2,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _fechaPago = picked);
    }
  }

  String _formatFecha(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<PagosAdminState>(pagosAdminProvider, (prev, next) {
      if (next.formState is PagoFormSuccess) {
        final msg = (next.formState as PagoFormSuccess).message;
        ref.read(pagosAdminProvider.notifier).resetFormState();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });

    final formState = ref.watch(pagosAdminProvider).formState;
    final isSaving = formState is PagoFormSaving;
    final formError =
        formState is PagoFormError ? (formState).message : null;

    return Container(
      decoration: BoxDecoration(
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
              // ── Título ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar Pago' : 'Nuevo Pago',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Error global ─────────────────────────────────────────────
              if (formError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    formError,
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── ID Venta ─────────────────────────────────────────────────
              _buildLabel('ID Venta *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _idVentaCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDec('Ej: 1'),
                validator: (v) {
                  final val = int.tryParse(v?.trim() ?? '');
                  if (val == null || val <= 0) {
                    return 'Ingresa un ID de venta válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Monto ────────────────────────────────────────────────────
              _buildLabel('Monto *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _montoCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDec('Ej: 1500.00'),
                validator: (v) {
                  final val = double.tryParse(v?.trim() ?? '');
                  if (val == null || val <= 0) {
                    return 'Ingresa un monto válido mayor que cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Método de pago ───────────────────────────────────────────
              _buildLabel('Método de pago *'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _metodoPago,
                dropdownColor: AppColors.surface2,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: _inputDec(null),
                items: MetodoPago.values
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.value,
                        child: Text(m.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _metodoPago = v);
                },
              ),
              const SizedBox(height: 16),

              // ── Estado ───────────────────────────────────────────────────
              _buildLabel('Estado *'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _estado,
                dropdownColor: AppColors.surface2,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: _inputDec(null),
                items: EstadoPago.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.value,
                        child: Text(e.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _estado = v);
                },
              ),
              const SizedBox(height: 16),

              // ── Fecha de pago ────────────────────────────────────────────
              _buildLabel('Fecha de pago (opcional)'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _seleccionarFecha,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatFecha(_fechaPago),
                        style: TextStyle(
                          color: _fechaPago != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      if (_fechaPago != null)
                        GestureDetector(
                          onTap: () => setState(() => _fechaPago = null),
                          child: Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Referencia ───────────────────────────────────────────────
              _buildLabel('Referencia (opcional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _referenciaCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                maxLength: 150,
                decoration: _inputDec('Ej: TXN-00123'),
              ),
              const SizedBox(height: 24),

              // ── Botón guardar ────────────────────────────────────────────
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
                          _isEditing ? 'Actualizar pago' : 'Registrar pago',
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

  // ── Helpers UI ────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDec(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textFaint),
      filled: true,
      fillColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
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
}
