// lib/presentation/widgets/documento_venta_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/documento_venta.dart';
import '../../theme/app_colors.dart';
import '../providers/documentos_venta_admin_provider.dart';

void showDocumentoVentaForm(BuildContext context, {DocumentoVenta? documento}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DocumentoVentaForm(documento: documento),
  );
}

class _DocumentoVentaForm extends ConsumerStatefulWidget {
  final DocumentoVenta? documento;
  const _DocumentoVentaForm({this.documento});

  @override
  ConsumerState<_DocumentoVentaForm> createState() =>
      _DocumentoVentaFormState();
}

class _DocumentoVentaFormState extends ConsumerState<_DocumentoVentaForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idVentaCtrl;
  late final TextEditingController _urlCtrl;

  String _tipoDocumento = TipoDocumento.factura.value;
  DateTime? _fechaSubida;

  bool get _isEditing => widget.documento != null;

  @override
  void initState() {
    super.initState();
    final d = widget.documento;
    _idVentaCtrl =
        TextEditingController(text: d != null ? d.idVenta.toString() : '');
    _urlCtrl = TextEditingController(text: d?.archivoUrl ?? '');
    _tipoDocumento = d?.tipoDocumento.value ?? TipoDocumento.factura.value;
    _fechaSubida = d?.fechaSubida;
  }

  @override
  void dispose() {
    _idVentaCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(documentosVentaAdminProvider.notifier);
    final idVenta = int.tryParse(_idVentaCtrl.text.trim()) ?? 0;

    if (_isEditing) {
      await notifier.actualizarDocumento(
        idDocumento: widget.documento!.idDocumento,
        idVenta: idVenta,
        tipoDocumento: _tipoDocumento,
        archivoUrl: _urlCtrl.text,
        fechaSubida: _fechaSubida,
      );
    } else {
      await notifier.crearDocumento(
        idVenta: idVenta,
        tipoDocumento: _tipoDocumento,
        archivoUrl: _urlCtrl.text,
        fechaSubida: _fechaSubida,
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSubida ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.surface2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _fechaSubida = picked;
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
    ref.listen<DocumentosVentaAdminState>(documentosVentaAdminProvider,
        (prev, next) {
      if (next.formState is DocumentoVentaFormSuccess) {
        final msg = (next.formState as DocumentoVentaFormSuccess).message;
        ref.read(documentosVentaAdminProvider.notifier).resetFormState();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
      }
    });

    final formState = ref.watch(documentosVentaAdminProvider).formState;
    final isSaving = formState is DocumentoVentaFormSaving;
    final formError =
        formState is DocumentoVentaFormError ? (formState).message : null;

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
                      _isEditing ? 'Editar Documento' : 'Nuevo Documento',
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
              SizedBox(height: 20),
              if (formError != null) ...[
                _ErrorBanner(message: formError),
                SizedBox(height: 16),
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
                  SizedBox(width: 12),
                  Expanded(
                    child: _FieldGroup(
                      label: 'Tipo *',
                      child: DropdownButtonFormField<String>(
                        value: _tipoDocumento,
                        dropdownColor: AppColors.surface2,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        isExpanded: true,
                        decoration: _inputDec(null),
                        items: TipoDocumento.values
                            .map((t) => DropdownMenuItem(
                                  value: t.value,
                                  child: Text(t.label,
                                      style: TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _tipoDocumento = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _FieldGroup(
                label: 'URL del Archivo *',
                child: TextFormField(
                  controller: _urlCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDec('Ej: https://...'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                ),
              ),
              SizedBox(height: 16),
              _FieldGroup(
                label: 'Fecha de subida',
                child: _DateBtn(
                  label: _formatFecha(_fechaSubida),
                  hasValue: _fechaSubida != null,
                  onTap: _selectDate,
                  onClear: () => setState(() => _fechaSubida = null),
                ),
              ),
              SizedBox(height: 24),
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
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onAccent,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Actualizar' : 'Registrar',
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
        SizedBox(height: 6),
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
            SizedBox(width: 6),
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
