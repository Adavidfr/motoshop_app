// lib/presentation/widgets/auth_button.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AuthButton extends StatelessWidget {
  final String   label;
  final VoidCallback? onPressed;
  final bool     isLoading;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isButtonEnabled = !isLoading && onPressed != null;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isButtonEnabled
            ? const LinearGradient(
                colors: [
                  Color(0xFFE50914),
                  Color(0xFFB30006),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: isButtonEnabled ? null : AppColors.surface2,
        boxShadow: isButtonEnabled
            ? [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isButtonEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}