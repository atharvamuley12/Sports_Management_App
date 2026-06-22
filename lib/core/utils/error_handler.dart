import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

class ErrorHandler {
  /// Shows a SnackBar with the error message and a COPY button action
  static void showError(BuildContext context, String title, dynamic error) {
    final rawError = error.toString();
    final message = '$title: $rawError';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        ),
        backgroundColor: AppTheme.darkCard,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'COPY',
          textColor: AppTheme.accentLime,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: rawError));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error copied to clipboard!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
