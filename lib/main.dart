import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';

bool _isAppConfigured = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Retrieve environment variables compiled via --dart-define
  var supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  var supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  // Fallback: Read config.json from local filesystem if compile-time variables are empty
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    if (!kIsWeb) {
      try {
        var dir = Directory.current;
        File? configFile;
        for (int i = 0; i < 5; i++) {
          final file = File('${dir.path}/config.json');
          if (file.existsSync()) {
            configFile = file;
            break;
          }
          // Navigate up to find root project directory
          if (dir.path == dir.parent.path) break; // Reached root directory
          dir = dir.parent;
        }

        if (configFile != null) {
          final config = jsonDecode(configFile.readAsStringSync());
          supabaseUrl = config['SUPABASE_URL'] ?? '';
          supabaseAnonKey = config['SUPABASE_ANON_KEY'] ?? '';
        }
      } catch (e) {
        debugPrint('Failed to load local config.json fallback: $e');
      }
    }
  }

  _isAppConfigured = supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  if (_isAppConfigured) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      _isAppConfigured = false;
    }
  } else {
    debugPrint('WARNING: SUPABASE_URL or SUPABASE_ANON_KEY is not defined!');
  }

  runApp(
    const ProviderScope(
      child: SportsAcademyApp(),
    ),
  );
}

class SportsAcademyApp extends ConsumerWidget {
  const SportsAcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isAppConfigured) {
      return MaterialApp(
        title: 'Sports Academy - Setup Required',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SetupRequiredScreen(),
      );
    }

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Sports Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        final isMobile = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;

        return Container(
          color: isDark ? const Color(0xFF0C0D0E) : const Color(0xFFE5D9C0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 395),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  static const String runCommand =
      'flutter run --dart-define-from-file=config.json';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentLime.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 80,
                  color: AppTheme.accentLime,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Supabase Setup Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The Flutter app needs your Supabase URL and Anon Key to connect. These were not passed during execution.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.darkBorder, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.accentTeal, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'How to Run the Application',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Option A: Run with the root .env file',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SelectableText(
                        runCommand,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: runCommand));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Run command copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Run Command'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppTheme.darkBorder),
                    const SizedBox(height: 12),
                    const Text(
                      'Option B: Run using pre-configured IDE profiles',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• VS Code: Select the "sports_academy_app" launch configuration.\n• Android Studio/IntelliJ: Run the "main.dart" configuration.\n• Or just run "flutter run --dart-define-from-file=.env" from the project root.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

