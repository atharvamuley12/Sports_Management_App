import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/shared_prefs_provider.dart';

final whatsappApiEnabledProvider = StateNotifierProvider<WhatsAppApiEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WhatsAppApiEnabledNotifier(prefs);
});

class WhatsAppApiEnabledNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'whatsapp_api_enabled';

  WhatsAppApiEnabledNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> toggle(bool val) async {
    await _prefs.setBool(_key, val);
    state = val;
  }
}

final whatsappServiceProvider = Provider<WhatsAppService>((ref) {
  final useApi = ref.watch(whatsappApiEnabledProvider);
  return WhatsAppService(useApi: useApi);
});

class WhatsAppService {
  final bool useApi;

  WhatsAppService({required this.useApi});

  Future<void> sendFeeReminder({
    required String phone,
    required String studentName,
    required double pendingDues,
  }) async {
    final message = "Hello! This is a reminder from Friends Sports Academy. "
        "The pending fee for $studentName is Rs. ${pendingDues.toStringAsFixed(0)}. "
        "Please make the payment as soon as possible. Thank you!";

    if (useApi) {
      // ────────────────────────────────────────────────────────────────
      // AUTOMATIC MODE — Mock API call that "uses tokens"
      // In production, replace this with a real Twilio / WhatsApp
      // Business API call. Currently simulates the API flow.
      // ────────────────────────────────────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 1000));
      debugPrint("API WhatsApp Sent: to $phone, message: $message");
    } else {
      // ────────────────────────────────────────────────────────────────
      // MANUAL MODE — Opens WhatsApp Web / Desktop via wa.me link
      // Works on all platforms including Windows desktop (opens in browser)
      // ────────────────────────────────────────────────────────────────
      String cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]+'), '');
      if (!cleanPhone.startsWith('+') && cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone'; // Default Indian country code
      }
      // Remove + if present (wa.me expects digits only)
      cleanPhone = cleanPhone.replaceAll('+', '');

      final uri = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");

      // On desktop (Windows/macOS/Linux) we always launch in browser.
      // canLaunchUrl may return false for wa.me on Windows because no
      // native handler is registered, so we skip that check and launch
      // directly — the user's default browser will open WhatsApp Web.
      try {
        final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
        if (isDesktop) {
          // Always launch via browser on desktop
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // On mobile, try native app first
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            // Fallback: open in browser anyway
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        }
      } catch (e) {
        throw Exception(
          "Could not open WhatsApp. Please ensure you have a browser installed. Error: $e",
        );
      }
    }
  }
}
