// lib/presentation/widgets/search_bar_widget.dart
//
// SearchBarWidget con debounce de 500 ms.
// Nombre diferente a SearchBar para evitar conflicto con material.SearchBar.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String?              initialValue;
  final String               hintText;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.hintText = 'Buscar...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _ctrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // refresh suffix icon
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(value.trim());
    });
  }

  void _clear() {
    _ctrl.clear();
    setState(() {});
    _timer?.cancel();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:      _ctrl,
      onChanged:       _onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText:   widget.hintText,
        hintStyle:  const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon:      const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: _clear,
              )
            : null,
        filled:      true,
        fillColor:   AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }
}
