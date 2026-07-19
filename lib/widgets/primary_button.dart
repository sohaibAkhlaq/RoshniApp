import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? customIcon;
  final bool isSecondary;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.customIcon,
    this.isSecondary = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final Color btnBgColor = backgroundColor ?? 
        (isSecondary ? Colors.white : theme.primaryColor);
    final Color btnTextColor = textColor ?? 
        (isSecondary ? theme.primaryColor : Colors.white);
    final BorderSide border = borderColor != null 
        ? BorderSide(color: borderColor!, width: 2)
        : (isSecondary ? BorderSide(color: theme.primaryColor, width: 2) : BorderSide.none);

    return Semantics(
      button: true,
      label: label,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: !isSecondary && backgroundColor == null
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withAlpha(64),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: btnBgColor,
            foregroundColor: btnTextColor,
            elevation: 0, // Handled by container shadow
            side: border,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (customIcon != null) ...[
                customIcon!,
                const SizedBox(width: 12),
              ] else if (icon != null) ...[
                Icon(icon, size: 26, color: btnTextColor),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: btnTextColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
