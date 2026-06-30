import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/student.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return StudentRepository(supabase);
});

/// Caches and returns image bytes for student photos from the private storage bucket.
final studentPhotoBytesProvider = FutureProvider.family.autoDispose<Uint8List, String>((ref, path) async {
  final supabase = ref.watch(supabaseClientProvider);
  return await supabase.storage
      .from('student_photos')
      .download(path)
      .timeout(const Duration(seconds: 20));
});

class StudentRepository {
  final SupabaseClient _supabase;

  StudentRepository(this._supabase);

  /// Fetches all students. Under RLS, coaches see only their batch's students.
  Future<List<Student>> getStudents() async {
    final response = await _supabase
        .from('students')
        .select()
        .order('name', ascending: true)
        .timeout(const Duration(seconds: 20));
    return (response as List).map((json) => Student.fromJson(json)).toList();
  }

  /// Uploads photo to the private student_photos bucket.
  Future<String?> uploadStudentPhoto(XFile photo) async {
    final bytes = await photo.readAsBytes();
    final fileExt = photo.name.split('.').last;
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$fileExt';
    final path = 'students/$fileName';

    await _supabase.storage.from('student_photos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: photo.mimeType, upsert: true),
        ).timeout(const Duration(seconds: 30));
    return path;
  }

  /// Creates a student record. Admin only.
  Future<void> createStudent({
    required String name,
    String? parentName,
    String? phone,
    int? age,
    required String sport,
    String? batchId,
    required double monthlyFee,
    required DateTime joinDate,
    required String status,
    XFile? photo,
  }) async {
    String? photoPath;
    if (photo != null) {
      photoPath = await uploadStudentPhoto(photo);
    }

    await _supabase.from('students').insert({
      'name': name,
      'parent_name': parentName,
      'phone': phone,
      'age': age,
      'sport': sport,
      'batch_id': batchId,
      'monthly_fee': monthlyFee,
      'join_date': "${joinDate.year.toString().padLeft(4, '0')}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}",
      'status': status,
      'photo_url': photoPath,
    }).timeout(const Duration(seconds: 20));
  }

  /// Updates a student record. Admin only.
  Future<void> updateStudent({
    required String id,
    required String name,
    String? parentName,
    String? phone,
    int? age,
    required String sport,
    String? batchId,
    required double monthlyFee,
    required DateTime joinDate,
    required String status,
    XFile? newPhoto,
    String? existingPhotoUrl,
  }) async {
    String? photoPath = existingPhotoUrl;
    if (newPhoto != null) {
      photoPath = await uploadStudentPhoto(newPhoto);
      if (existingPhotoUrl != null && existingPhotoUrl.isNotEmpty) {
        try {
          await _supabase.storage.from('student_photos').remove([existingPhotoUrl]);
        } catch (_) {}
      }
    }

    await _supabase.from('students').update({
      'name': name,
      'parent_name': parentName,
      'phone': phone,
      'age': age,
      'sport': sport,
      'batch_id': batchId,
      'monthly_fee': monthlyFee,
      'join_date': "${joinDate.year.toString().padLeft(4, '0')}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}",
      'status': status,
      'photo_url': photoPath,
    }).eq('id', id).timeout(const Duration(seconds: 20));
  }

  /// Deletes a student record. Admin only.
  Future<void> deleteStudent(String id, {String? photoUrl}) async {
    await _supabase.from('students').delete().eq('id', id).timeout(const Duration(seconds: 20));
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        await _supabase.storage.from('student_photos').remove([photoUrl]);
      } catch (_) {}
    }
  }
}
