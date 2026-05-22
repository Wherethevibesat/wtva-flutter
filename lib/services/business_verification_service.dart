import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_bootstrap.dart';
import 'supabase_data.dart';

/// Uploads business license / EIN documents to Supabase Storage.
class BusinessVerificationService {
  BusinessVerificationService._();
  static final BusinessVerificationService instance = BusinessVerificationService._();

  static const _bucket = 'business-verification';

  Future<PlatformFile?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  Future<PlatformFile?> pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    return PlatformFile(
      name: image.name,
      size: bytes.length,
      bytes: bytes,
      path: image.path,
    );
  }

  /// Returns storage path (not public URL) saved on the venue row.
  Future<String?> uploadForOwner({
    required String ownerId,
    required PlatformFile file,
  }) async {
    if (!SupabaseData.syncAuth) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;

    final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
    if (bytes == null || bytes.isEmpty) return null;

    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$ownerId/verification_${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await client.storage.from(_bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: _mimeForName(safeName),
        upsert: true,
      ),
    );

    return path;
  }

  String _mimeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
