import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

class ErrorHandler {
  /// Translates technical/database exceptions to friendly, common-man explanations.
  static String _getFriendlyErrorMessage(dynamic error) {
    if (error == null) return "An unexpected error occurred. Please try again.";

    final errorString = error.toString().toLowerCase();

    // 1. Connection / Timeout Errors
    if (errorString.contains('socketexception') ||
        errorString.contains('handshakeexception') ||
        errorString.contains('clientexception') ||
        errorString.contains('timeoutexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network_error')) {
      return "Network connection issue. Please check your internet connection and try again.";
    }

    // 2. Supabase Auth Exceptions
    if (errorString.contains('authexception')) {
      if (errorString.contains('invalid login credentials') || errorString.contains('invalid_credentials')) {
        return "Incorrect email or password. Please double check and try again.";
      }
      if (errorString.contains('email_not_confirmed') || errorString.contains('email not confirmed')) {
        return "Your email address is not verified. Please check your inbox for the confirmation link.";
      }
      if (errorString.contains('user already exists') || errorString.contains('user_already_exists')) {
        return "An account with this email address already exists.";
      }
      if (errorString.contains('password should be at least')) {
        return "Password is too weak. It must be at least 6 characters long.";
      }
      return "Authentication failed. Please check your credentials and try again.";
    }

    // 3. Supabase Postgrest (Database) Exceptions
    if (errorString.contains('postgrestexception')) {
      // PGRST204: Could not find column / table
      if (errorString.contains('pgrst204') || errorString.contains('could not find the') || errorString.contains('column')) {
        return "Database schema mismatch. Please ensure you have run the latest SQL migration script in your Supabase dashboard SQL editor.";
      }
      // Unique Constraint (23505)
      if (errorString.contains('23505') || errorString.contains('duplicate key value') || errorString.contains('already exists')) {
        return "A record with these details already exists. Duplicate entries are not allowed.";
      }
      // Foreign Key Constraint (23503)
      if (errorString.contains('23503') || errorString.contains('violates foreign key')) {
        return "Cannot save or delete. This record is linked to other details in the database.";
      }
      // Permission Denied / RLS (42501)
      if (errorString.contains('42501') || errorString.contains('permission denied') || errorString.contains('row-level security')) {
        return "Access denied. You do not have permission to view or perform this action.";
      }
      return "Database error. Please check your connection or data entry and try again.";
    }

    // 4. Input or generic validation messages in common exceptions
    if (errorString.contains('format_exception') || errorString.contains('formatexception')) {
      return "Invalid number or input format. Please check the entered fields.";
    }

    if (errorString.contains('duplicate key value') ||
        errorString.contains('already exists') ||
        errorString.contains('duplicate entries are not allowed')) {
      return "A record with these details already exists. Duplicate entries are not allowed.";
    }

    // 5. Default fallback
    return "Something went wrong. Please check details or try again later.";
  }

  /// Shows a SnackBar with a user-friendly message and a COPY button action that copies raw developer details.
  static void showError(BuildContext context, String title, dynamic error) {
    final rawError = error.toString();
    final friendlyMsg = _getFriendlyErrorMessage(error);
    final displayMessage = '$title: $friendlyMsg';

    // Format a detailed report for copy-pasting to developers
    final detailedCopyReport = '--- ANTIGRAVITY DEBUG INFO ---\n'
        'Context: $title\n'
        'User Message: $friendlyMsg\n'
        'Raw Exception:\n$rawError\n'
        'Timestamp: ${DateTime.now().toUtc().toIso8601String()}\n'
        '------------------------------';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          displayMessage,
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
            Clipboard.setData(ClipboardData(text: detailedCopyReport));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Detailed developer report copied to clipboard!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
