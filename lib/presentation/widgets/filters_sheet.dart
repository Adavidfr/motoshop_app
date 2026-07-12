// lib/presentation/widgets/filters_sheet.dart

import 'package:flutter/material.dart';
import '../../domain/model/category.dart';
import '../../theme/app_colors.dart';

const _orderOptions = [
  (null,          'Relevancia'),
  ('price',       'Precio ↑'),
  ('-price',      'Precio ↓'),
  ('name',        'Nombre A→Z'),
  ('-name',       'Nombre Z→A'),
  ('-created_at', 'Recientes'),
];

class ProductFilters {
  final int?    categoryId;
  final double? minPrice;
  final double? maxPrice;
  final String? ordering;

  const ProductFilters({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.ordering,
  });
}

/// Muestra el BottomSheet de filtros y devuelve los filtros seleccionados.
Future<ProductFilters?> showFiltersSheet({
  required BuildContext     context,
  required ProductFilters   activeFilters,
  required List<Category>   categories,
}) {
  return showModalBottomSheet<ProductFilters>(
    context:          context,
    isScrollControlled: true,
    backgroundColor:  AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FiltersSheet(
      activeFilters: activeFilters,
      categories:    categories,
    ),
  );
}

class _FiltersSheet extends StatefulWidget {
  final ProductFilters  activeFilters;
  final List<Category>  categories;
  const _FiltersSheet({required this.activeFilters, required this.categories});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late int?    _categoryId;
  late String? _ordering;
  late double? _minPrice;
  late double? _maxPrice;

  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoryId = widget.activeFilters.categoryId;
    _ordering   = widget.activeFilters.ordering;
    _minPrice   = widget.activeFilters.minPrice;
    _maxPrice   = widget.activeFilters.maxPrice;
    if (_minPrice != null) _minCtrl.text = _minPrice!.toStringAsFixed(0);
    if (_maxPrice != null) _maxCtrl.text = _maxPrice!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.4,
      maxChildSize:     0.95,
      expand:           false,
      builder: (_, sc) => ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Handle
          Center(
            child: Container(
              width:        40,
              height:       4,
              margin:       const EdgeInsets.only(bottom: 20),
              decoration:   BoxDecoration(
                color:        AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text('Filtros', style: tt.titleLarge?.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 20),

          // ── Categoría ─────────────────────────────────────
          Text('Categoría', style: tt.titleSmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing:  8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label:     const Text('Todas'),
                selected:  _categoryId == null,
                onSelected: (_) => setState(() => _categoryId = null),
              ),
              for (final cat in widget.categories)
                ChoiceChip(
                  label:     Text(cat.name),
                  selected:  _categoryId == cat.id,
                  onSelected: (_) => setState(() => _categoryId = cat.id),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Rango de precio ───────────────────────────────
          Text('Rango de precio', style: tt.titleSmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller:  _minCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style:        const TextStyle(color: AppColors.textPrimary),
                  decoration:   _inputDeco('Mín. \$'),
                  onChanged:    (v) => _minPrice = double.tryParse(v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller:  _maxCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style:        const TextStyle(color: AppColors.textPrimary),
                  decoration:   _inputDeco('Máx. \$'),
                  onChanged:    (v) => _maxPrice = double.tryParse(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Ordenamiento ──────────────────────────────────
          Text('Ordenar por', style: tt.titleSmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing:  8,
            runSpacing: 8,
            children: [
              for (final opt in _orderOptions)
                ChoiceChip(
                  label:     Text(opt.$2),
                  selected:  _ordering == opt.$1,
                  onSelected: (_) => setState(() => _ordering = opt.$1),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Botones ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _categoryId = null;
                      _ordering   = null;
                      _minPrice   = null;
                      _maxPrice   = null;
                      _minCtrl.clear();
                      _maxCtrl.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    ProductFilters(
                      categoryId: _categoryId,
                      minPrice:   _minPrice,
                      maxPrice:   _maxPrice,
                      ordering:   _ordering,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    hintText:    label,
    hintStyle:   const TextStyle(color: AppColors.textSecondary),
    filled:      true,
    fillColor:   AppColors.surface2,
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:   const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:   const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:   const BorderSide(color: AppColors.accent, width: 2),
    ),
  );
}
