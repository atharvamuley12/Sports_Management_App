import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';

class ExportHelper {
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  /// Generates a timestamped file name.
  /// Example: Students_List_2026-07-11_23-04-00
  static String _buildFileName(String title) {
    final now = DateTime.now();
    final datePart = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    // Sanitize the title: replace spaces with underscores, remove special characters
    final sanitized = title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), '_');
    return '${sanitized}_$datePart';
  }

  /// Fetches a Unicode-compliant regular font (Roboto) with local in-memory caching and Helvetica fallback.
  static Future<pw.Font> _getRegularFont() async {
    if (_cachedRegularFont != null) return _cachedRegularFont!;
    try {
      final fontData = await NetworkAssetBundle(
        Uri.parse('https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Mu4mxK.ttf'),
      ).load('');
      _cachedRegularFont = pw.Font.ttf(fontData);
      return _cachedRegularFont!;
    } catch (e) {
      debugPrint('Failed to load online regular font, using Helvetica fallback: $e');
      return pw.Font.helvetica();
    }
  }

  /// Fetches a Unicode-compliant bold font (Roboto-Bold) with local in-memory caching and Helvetica fallback.
  static Future<pw.Font> _getBoldFont() async {
    if (_cachedBoldFont != null) return _cachedBoldFont!;
    try {
      final fontData = await NetworkAssetBundle(
        Uri.parse('https://fonts.gstatic.com/s/roboto/v30/KFOlCnqEu92Fr1MmWUlfBBc4.ttf'),
      ).load('');
      _cachedBoldFont = pw.Font.ttf(fontData);
      return _cachedBoldFont!;
    } catch (e) {
      debugPrint('Failed to load online bold font, using Helvetica fallback: $e');
      return pw.Font.helveticaBold();
    }
  }

  /// Helper to get the downloads directory path, with standard fallback options.
  static Future<String?> _getDownloadsPath() async {
    try {
      if (Platform.isWindows) {
        final dir = await getDownloadsDirectory();
        if (dir != null) return dir.path;

        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final winDownloads = '$userProfile\\Downloads';
          if (await Directory(winDownloads).exists()) {
            return winDownloads;
          }
        }
      }

      final dir = await getDownloadsDirectory();
      if (dir != null) return dir.path;

      final docs = await getApplicationDocumentsDirectory();
      return docs.path;
    } catch (_) {
      return null;
    }
  }

  /// Exports tabular data to PDF or Excel and triggers download/share.
  static Future<void> exportData({
    required BuildContext context,
    required String fileName, // legacy param kept for backward compat but not used for final name
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required bool exportAsPdf,
    bool share = false,
  }) async {
    try {
      // Generate a descriptive timestamped file name from the report title
      final timestampedName = _buildFileName(title);

      if (exportAsPdf) {
        await _exportToPdf(context, timestampedName, title, headers, rows, share);
      } else {
        await _exportToExcel(context, timestampedName, title, headers, rows, share);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> _exportToPdf(
    BuildContext context,
    String fileName,
    String title,
    List<String> headers,
    List<List<String>> rows,
    bool share,
  ) async {
    // Show a loading SnackBar while we fetch fonts and build the PDF
    final loadingSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating PDF report... Please wait.'),
          ],
        ),
        duration: Duration(days: 1), // Indefinite until manually hidden
      ),
    );

    try {
      final pdf = pw.Document();
      final regularFont = await _getRegularFont();
      final boldFont = await _getBoldFont();

      // Add page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(font: boldFont, fontSize: 20),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on: ${DateTime.now().toLocal().toString().split('.')[0]}',
                      style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: rows,
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
                cellStyle: pw.TextStyle(font: regularFont, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellHeight: 22,
                cellAlignments: {
                  for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft,
                },
              ),
            ];
          },
        ),
      );

      final fileBytes = await pdf.save();

      // Dismiss the loading snackbar
      loadingSnackBar.close();

      if (kIsWeb) {
        final blob = html.Blob([fileBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', '$fileName.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF downloaded successfully!'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Always save to a real path first (Downloads on desktop, temp on mobile)
        String savePath;

        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          final downloadsPath = await _getDownloadsPath();
          if (downloadsPath != null) {
            savePath = '$downloadsPath/$fileName.pdf';
          } else {
            final tempDir = await getTemporaryDirectory();
            savePath = '${tempDir.path}/$fileName.pdf';
          }
        } else {
          final tempDir = await getTemporaryDirectory();
          savePath = '${tempDir.path}/$fileName.pdf';
        }

        final file = await File(savePath).create(recursive: true);
        await file.writeAsBytes(fileBytes);

        if (context.mounted) {
          final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
          if (share && !isDesktop) {
            // Mobile: share via native share sheet (WhatsApp, etc.)
            await Share.shareXFiles(
              [XFile(file.path)],
              subject: '$title - PDF Report',
              text: '$title\nExported on: ${DateTime.now().toLocal().toString().split('.')[0]}',
            );
          } else {
            // Desktop or Download mode: save to Downloads and show snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to Downloads: $fileName.pdf'),
                backgroundColor: AppTheme.successGreen,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'OPEN',
                  textColor: Colors.white,
                  onPressed: () async {
                    final uri = Uri.file(file.path);
                    try {
                      await launchUrl(uri);
                    } catch (e) {
                      debugPrint('Could not launch file: $e');
                    }
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      loadingSnackBar.close();
      rethrow;
    }
  }

  static Future<void> _exportToExcel(
    BuildContext context,
    String fileName,
    String title,
    List<String> headers,
    List<List<String>> rows,
    bool share,
  ) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    // Append Header Row
    sheet.appendRow(headers.map((h) => ex.TextCellValue(h)).toList());

    // Append Data Rows
    for (final row in rows) {
      sheet.appendRow(row.map((val) => ex.TextCellValue(val)).toList());
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) throw Exception('Failed to encode excel file');

    if (kIsWeb) {
      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', '$fileName.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel spreadsheet downloaded successfully!'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      // Always save to a real path first
      String savePath;

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final downloadsPath = await _getDownloadsPath();
        if (downloadsPath != null) {
          savePath = '$downloadsPath/$fileName.xlsx';
        } else {
          final tempDir = await getTemporaryDirectory();
          savePath = '${tempDir.path}/$fileName.xlsx';
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        savePath = '${tempDir.path}/$fileName.xlsx';
      }

      final file = await File(savePath).create(recursive: true);
      await file.writeAsBytes(fileBytes);

      if (context.mounted) {
        final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
        if (share && !isDesktop) {
          // Mobile: share via native share sheet (WhatsApp, etc.)
          await Share.shareXFiles(
            [XFile(file.path)],
            subject: '$title - Excel Report',
            text: '$title\nExported on: ${DateTime.now().toLocal().toString().split('.')[0]}',
          );
        } else {
          // Desktop or Download mode: save to Downloads and show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to Downloads: $fileName.xlsx'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OPEN',
                textColor: Colors.white,
                onPressed: () async {
                  final uri = Uri.file(file.path);
                  try {
                    await launchUrl(uri);
                  } catch (e) {
                    debugPrint('Could not launch file: $e');
                  }
                },
              ),
            ),
          );
        }
      }
    }
  }
}
